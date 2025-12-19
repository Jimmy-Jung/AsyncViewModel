import ProjectDescription

// MARK: - Project Templates

extension Project {
    /// Feature 모듈 생성 템플릿
    public static func featureModule(
        name: String,
        dependencies: [TargetDependency] = [],
        includeTests: Bool = true
    ) -> Project {
        var targets: [Target] = [
            .target(
                name: name,
                destinations: .iOS,
                product: .framework,
                bundleId: "io.github.asyncviewmodel.\(name.lowercased())",
                deploymentTargets: .iOS("15.0"),
                sources: ["Sources/\(name)/**"],
                dependencies: dependencies,
                settings: .targetSettings()
            )
        ]
        
        if includeTests {
            targets.append(
                .target(
                    name: "\(name)Tests",
                    destinations: .iOS,
                    product: .unitTests,
                    bundleId: "io.github.asyncviewmodel.\(name.lowercased()).tests",
                    deploymentTargets: .iOS("15.0"),
                    sources: ["Tests/\(name)Tests/**"],
                    resources: ["Tests/\(name)Tests/Resources/**"],
                    dependencies: [
                        .target(name: name)
                    ],
                    settings: .targetSettings()
                )
            )
        }
        
        return Project(
            name: name,
            targets: targets
        )
    }
    
    /// Core 모듈 생성 템플릿
    public static func coreModule(
        name: String,
        bundleIdSuffix: String? = nil,
        productName: String? = nil,
        dependencies: [TargetDependency] = [],
        includeTests: Bool = true
    ) -> Project {
        let suffix = bundleIdSuffix ?? name.lowercased()
        let product = productName ?? name
        
        var targets: [Target] = [
            .target(
                name: name,
                destinations: .iOS,
                product: .framework,
                productName: product,
                bundleId: "io.github.asyncviewmodel.core.\(suffix)",
                deploymentTargets: .iOS("15.0"),
                sources: ["Sources/\(name)/**"],
                resources: ["Sources/\(name)/Resources/**"],
                dependencies: dependencies,
                settings: .targetSettings()
            )
        ]
        
        if includeTests {
            targets.append(
                .target(
                    name: "\(name)Tests",
                    destinations: .iOS,
                    product: .unitTests,
                    productName: "\(product)Tests",
                    bundleId: "io.github.asyncviewmodel.core.\(suffix).tests",
                    deploymentTargets: .iOS("15.0"),
                    sources: ["Tests/\(name)Tests/**"],
                    resources: ["Tests/\(name)Tests/Resources/**"],
                    dependencies: [
                        .target(name: name)
                    ],
                    settings: .targetSettings()
                )
            )
        }
        
        return Project(
            name: name,
            targets: targets
        )
    }
}
