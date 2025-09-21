import Foundation
import OSLog
import Network
import Combine
import CryptoKit

/// Enterprise CDN management system with intelligent caching and failover
@available(iOS 17.0, *)
public final class CDNManager: ObservableObject {
    public static let shared = CDNManager()

    private let logger = Logger(subsystem: "com.mytasklist.sharedkit", category: "CDNManager")
    private let networkMonitor = NWPathMonitor()
    private let session: URLSession
    private let cache: CDNCache
    private let failoverManager: FailoverManager
    private let analyticsCollector: CDNAnalyticsCollector

    @Published public private(set) var isOnline: Bool = true
    @Published public private(set) var currentRegion: CDNRegion = .auto
    @Published public private(set) var performance: CDNPerformanceMetrics = .default

    private let monitorQueue = DispatchQueue(label: "com.mytasklist.cdn.monitor")
    private var cancellables = Set<AnyCancellable>()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 30.0
        config.urlCache = nil // We handle our own caching
        config.waitsForConnectivity = true

        self.session = URLSession(configuration: config)
        self.cache = CDNCache()
        self.failoverManager = FailoverManager()
        self.analyticsCollector = CDNAnalyticsCollector()

        setupNetworkMonitoring()
        logger.info("CDNManager initialized with enterprise-grade failover")
    }

    /// Loads asset from CDN with intelligent caching and failover
    public func loadAsset(
        named assetName: String,
        quality: ImageQuality = .auto,
        priority: CDNPriority = .normal
    ) async throws -> Data {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.debug("Loading asset: \(assetName) with quality: \(String(describing: quality))")

        // Check cache first
        if let cachedData = await cache.getData(for: assetName, quality: quality) {
            logger.debug("Cache hit for asset: \(assetName)")
            analyticsCollector.recordCacheHit(assetName: assetName)
            return cachedData
        }

        // Load from CDN with failover
        let data = try await loadFromCDNWithFailover(
            assetName: assetName,
            quality: quality,
            priority: priority
        )

        // Cache the result
        await cache.storeData(data, for: assetName, quality: quality)

        let loadTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        analyticsCollector.recordAssetLoad(
            assetName: assetName,
            loadTimeMs: loadTime,
            dataSize: data.count,
            source: .cdn
        )

        let ms = String(format: "%.1f", loadTime)
        logger.debug("Asset loaded: \(assetName) (\(data.count) bytes, \(ms)ms)")
        return data
    }

    /// Preloads critical assets for optimal performance
    public func preloadAssets(_ assetNames: [String], quality: ImageQuality = .high) async {
        logger.info("Preloading \(assetNames.count) critical assets")

        await withTaskGroup(of: Void.self) { group in
            for assetName in assetNames {
                group.addTask { [weak self] in
                    do {
                        _ = try await self?.loadAsset(named: assetName, quality: quality, priority: .high)
                    } catch {
                        self?.logger.error("Preload failed for \(assetName): \(error.localizedDescription)")
                    }
                }
            }
        }

        logger.info("Asset preloading completed")
    }

    /// Purges cache for specific assets
    public func purgeCache(for assetNames: [String]? = nil) async {
        if let specificAssets = assetNames {
            await cache.remove(assetNames: specificAssets)
            logger.info("Cache purged for \(specificAssets.count) specific assets")
        } else {
            await cache.purgeAll()
            logger.info("Entire cache purged")
        }
    }

    /// Gets performance metrics for the CDN
    public func getPerformanceMetrics() -> CDNPerformanceMetrics {
        return analyticsCollector.currentMetrics
    }

    /// Gets cache statistics
    public func getCacheStatistics() async -> CDNCacheStatistics {
        return await cache.getStatistics()
    }

    // MARK: - Private Methods

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                self?.updateNetworkOptimization(path: path)
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    private func updateNetworkOptimization(path: NWPath) {
        // Adjust CDN behavior based on network conditions
        if path.isExpensive {
            // On cellular, prefer lower quality and more aggressive caching
            logger.info("Expensive network detected, optimizing for data usage")
        }

        if path.isConstrained {
            // On low-data mode, minimize transfers
            logger.info("Constrained network detected, minimizing transfers")
        }
    }

    private func loadFromCDNWithFailover(
        assetName: String,
        quality: ImageQuality,
        priority: CDNPriority
    ) async throws -> Data {
        let regions = failoverManager.getOptimalRegions(for: currentRegion)

        for (index, region) in regions.enumerated() {
            do {
                let url = buildCDNURL(assetName: assetName, quality: quality, region: region)
                let data = try await performRequest(url: url, priority: priority)

                if index > 0 {
                    // We failed over, update region preference
                    currentRegion = region
                    logger.info("Failover successful to region: \(region.rawValue)")
                }

                return data
            } catch {
                logger.warning("Failed to load from region \(region.rawValue): \(error.localizedDescription)")

                if index == regions.count - 1 {
                    // Last region, propagate error
                    throw CDNError.allRegionsFailed(underlying: error)
                }

                // Try next region
                continue
            }
        }

        throw CDNError.noRegionsAvailable
    }

    private func buildCDNURL(assetName: String, quality: ImageQuality, region: CDNRegion) -> URL {
        let baseURL = region.baseURL
        let qualityParam = quality == .auto ? "" : "?q=\(Int(quality.compressionRatio * 100))"
        let path = "/assets/v2/\(assetName).webp\(qualityParam)"

        return baseURL.appendingPathComponent(path)
    }

    private func performRequest(url: URL, priority: CDNPriority) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("MyTaskList/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("gzip, br", forHTTPHeaderField: "Accept-Encoding")

        // Set priority-based timeout
        request.timeoutInterval = priority.timeoutInterval

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CDNError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CDNError.httpError(statusCode: httpResponse.statusCode)
        }

        // Validate content
        guard data.count > 0 else {
            throw CDNError.emptyResponse
        }

        return data
    }
}

// MARK: - Supporting Types

/// CDN regions for geographic optimization
public enum CDNRegion: String, CaseIterable {
    case auto = "auto"
    case usEast = "us-east-1"
    case usWest = "us-west-2"
    case europe = "eu-central-1"
    case asiaPacific = "ap-southeast-1"

    var baseURL: URL {
        switch self {
        case .auto, .usEast:
            return URL(string: "https://cdn-us-east.mytasklist.com")!
        case .usWest:
            return URL(string: "https://cdn-us-west.mytasklist.com")!
        case .europe:
            return URL(string: "https://cdn-eu.mytasklist.com")!
        case .asiaPacific:
            return URL(string: "https://cdn-ap.mytasklist.com")!
        }
    }
}

/// CDN request priority levels
public enum CDNPriority {
    case low
    case normal
    case high
    case critical

    var timeoutInterval: TimeInterval {
        switch self {
        case .low: return 30.0
        case .normal: return 15.0
        case .high: return 10.0
        case .critical: return 5.0
        }
    }
}

/// CDN asset loading source
public enum CDNSource {
    case cache
    case cdn
    case failover
}

/// CDN error types
public enum CDNError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case emptyResponse
    case noRegionsAvailable
    case allRegionsFailed(underlying: Error)
    case cacheError(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from CDN"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .emptyResponse:
            return "Empty response from CDN"
        case .noRegionsAvailable:
            return "No CDN regions available"
        case .allRegionsFailed(let error):
            return "All CDN regions failed: \(error.localizedDescription)"
        case .cacheError(let error):
            return "Cache error: \(error.localizedDescription)"
        }
    }
}

/// CDN performance metrics
public struct CDNPerformanceMetrics {
    public let averageLoadTime: Double
    public let cacheHitRate: Double
    public let failoverRate: Double
    public let totalRequests: Int
    public let totalDataTransferred: Int64

    public static let `default` = CDNPerformanceMetrics(
        averageLoadTime: 0.0,
        cacheHitRate: 0.0,
        failoverRate: 0.0,
        totalRequests: 0,
        totalDataTransferred: 0
    )
}

/// CDN cache statistics
public struct CDNCacheStatistics {
    public let totalItems: Int
    public let totalSize: Int64
    public let hitRate: Double
    public let evictionCount: Int
    public let lastPurgeDate: Date?
}

// MARK: - Cache Implementation

/// Intelligent CDN cache with LRU eviction
@available(iOS 17.0, *)
actor CDNCache {
    private let logger = Logger(subsystem: "com.mytasklist.sharedkit", category: "CDNCache")
    private var storage: [String: CacheEntry] = [:]
    private var accessOrder: [String] = []

    private let maxSize: Int64 = 50 * 1024 * 1024 // 50MB
    private let maxItems: Int = 1000
    private var currentSize: Int64 = 0

    func getData(for assetName: String, quality: ImageQuality) -> Data? {
        let key = cacheKey(assetName: assetName, quality: quality)

        guard let entry = storage[key] else {
            return nil
        }

        // Check if entry is still valid
        if entry.isExpired {
            storage.removeValue(forKey: key)
            accessOrder.removeAll { $0 == key }
            currentSize -= Int64(entry.data.count)
            return nil
        }

        // Update access order for LRU
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(key)

        return entry.data
    }

    func storeData(_ data: Data, for assetName: String, quality: ImageQuality) {
        let key = cacheKey(assetName: assetName, quality: quality)
        let dataSize = Int64(data.count)

        // Remove existing entry if present
        if let existingEntry = storage[key] {
            currentSize -= Int64(existingEntry.data.count)
        }

        // Evict if necessary
        while (currentSize + dataSize > maxSize) || (storage.count >= maxItems) {
            evictLeastRecentlyUsed()
        }

        // Store new entry
        let entry = CacheEntry(
            data: data,
            createdAt: Date(),
            lastAccessedAt: Date(),
            expiresAt: Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        )

        storage[key] = entry
        currentSize += dataSize

        // Update access order
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(key)

        logger.debug("Cached asset: \(key) (\(dataSize) bytes)")
    }

    func remove(assetNames: [String]) {
        for assetName in assetNames {
            let keysToRemove = storage.keys.filter { $0.hasPrefix(assetName) }
            for key in keysToRemove {
                if let entry = storage.removeValue(forKey: key) {
                    currentSize -= Int64(entry.data.count)
                }
                accessOrder.removeAll { $0 == key }
            }
        }
    }

    func purgeAll() {
        storage.removeAll()
        accessOrder.removeAll()
        currentSize = 0
        logger.info("Cache purged completely")
    }

    func getStatistics() -> CDNCacheStatistics {
        return CDNCacheStatistics(
            totalItems: storage.count,
            totalSize: currentSize,
            hitRate: 0.0, // Would be calculated from analytics
            evictionCount: 0, // Would be tracked
            lastPurgeDate: nil // Would be tracked
        )
    }

    private func cacheKey(assetName: String, quality: ImageQuality) -> String {
        return "\(assetName)_\(quality.compressionRatio)"
    }

    private func evictLeastRecentlyUsed() {
        guard let oldestKey = accessOrder.first,
              let entry = storage.removeValue(forKey: oldestKey) else {
            return
        }

        currentSize -= Int64(entry.data.count)
        accessOrder.removeFirst()
        logger.debug("Evicted cache entry: \(oldestKey)")
    }
}

/// Cache entry with expiration
struct CacheEntry {
    let data: Data
    let createdAt: Date
    let lastAccessedAt: Date
    let expiresAt: Date

    var isExpired: Bool {
        return Date() > expiresAt
    }
}

// MARK: - Failover Manager

/// Intelligent failover management
@available(iOS 17.0, *)
final class FailoverManager {
    private let logger = Logger(subsystem: "com.mytasklist.sharedkit", category: "FailoverManager")
    private var regionHealth: [CDNRegion: RegionHealth] = [:]

    func getOptimalRegions(for preferredRegion: CDNRegion) -> [CDNRegion] {
        let allRegions = CDNRegion.allCases.filter { $0 != .auto }

        // Sort by health score and geographic proximity
        let sortedRegions = allRegions.sorted { region1, region2 in
            let health1 = regionHealth[region1]?.score ?? 1.0
            let health2 = regionHealth[region2]?.score ?? 1.0

            if health1 != health2 {
                return health1 > health2
            }

            // Prefer original region if health is equal
            if region1 == preferredRegion { return true }
            if region2 == preferredRegion { return false }

            return false
        }

        logger.debug("Optimal region order: \(sortedRegions.map { $0.rawValue })")
        return sortedRegions
    }

    func recordFailure(for region: CDNRegion) {
        var health = regionHealth[region] ?? RegionHealth()
        health.recordFailure()
        regionHealth[region] = health

        logger.warning("Recorded failure for region: \(region.rawValue), health: \(health.score)")
    }

    func recordSuccess(for region: CDNRegion) {
        var health = regionHealth[region] ?? RegionHealth()
        health.recordSuccess()
        regionHealth[region] = health
    }
}

/// Region health tracking
struct RegionHealth {
    private var successes: Int = 0
    private var failures: Int = 0
    private var lastFailure: Date?

    var score: Double {
        let total = successes + failures
        guard total > 0 else { return 1.0 }

        let successRate = Double(successes) / Double(total)

        // Penalize recent failures
        if let lastFailure = lastFailure,
           Date().timeIntervalSince(lastFailure) < 300 { // 5 minutes
            return successRate * 0.5
        }

        return successRate
    }

    mutating func recordSuccess() {
        successes += 1
    }

    mutating func recordFailure() {
        failures += 1
        lastFailure = Date()
    }
}

// MARK: - Analytics Collector

/// CDN analytics and performance tracking
@available(iOS 17.0, *)
final class CDNAnalyticsCollector {
    private let logger = Logger(subsystem: "com.mytasklist.sharedkit", category: "CDNAnalytics")
    private var metrics: CDNPerformanceMetrics = .default
    private var loadTimes: [Double] = []
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0

    var currentMetrics: CDNPerformanceMetrics {
        return CDNPerformanceMetrics(
            averageLoadTime: loadTimes.isEmpty ? 0.0 : loadTimes.reduce(0, +) / Double(loadTimes.count),
            cacheHitRate: totalCacheRequests == 0 ? 0.0 : Double(cacheHits) / Double(totalCacheRequests),
            failoverRate: 0.0, // Would be calculated
            totalRequests: loadTimes.count,
            totalDataTransferred: 0 // Would be tracked
        )
    }

    private var totalCacheRequests: Int {
        return cacheHits + cacheMisses
    }

    func recordAssetLoad(assetName: String, loadTimeMs: Double, dataSize: Int, source: CDNSource) {
        loadTimes.append(loadTimeMs)

        if source == .cache {
            cacheHits += 1
        } else {
            cacheMisses += 1
        }

        // Keep only recent data points
        if loadTimes.count > 1000 {
            loadTimes.removeFirst(100)
        }

        logger.debug("Asset load recorded: \(assetName), \(loadTimeMs)ms, \(String(describing: source))")
    }

    func recordCacheHit(assetName: String) {
        cacheHits += 1
        logger.debug("Cache hit recorded: \(assetName)")
    }
}
