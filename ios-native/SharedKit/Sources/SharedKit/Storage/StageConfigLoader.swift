import Foundation

public final class StageConfigLoader {
    public static let shared = StageConfigLoader()

    private init() {}

    public func load(bundle: Bundle = .main) throws -> StageCfg {
        guard let url = bundle.url(forResource: "StageConfig", withExtension: "json") else {
            return StageCfg.defaultConfig()
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(StageCfg.self, from: data)
    }

    public func loadStageConfig(bundle: Bundle = .main) -> StageCfg {
        do {
            return try load(bundle: bundle)
        } catch {
            // Fallback to default config if loading fails
            return StageCfg.defaultConfig()
        }
    }
}
