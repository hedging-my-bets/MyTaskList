import Foundation

public final class StageConfigLoader {
    public init() {}
    public func load(bundle: Bundle = .main) throws -> StageCfg {
        if let url = bundle.url(forResource: "StageConfig", withExtension: "json") {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(StageCfg.self, from: data)
        }
        return StageCfg.defaultConfig()
    }
}


