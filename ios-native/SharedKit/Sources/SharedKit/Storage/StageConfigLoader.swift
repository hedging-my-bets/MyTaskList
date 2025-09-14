import Foundation

public final class StageConfigLoader {
    public init() {}

    public func load(bundle: Bundle = .main) throws -> StageCfg {
        guard let url = bundle.url(forResource: "StageConfig", withExtension: "json") else {
            return StageCfg.defaultConfig()
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(StageCfg.self, from: data)
    }
}
