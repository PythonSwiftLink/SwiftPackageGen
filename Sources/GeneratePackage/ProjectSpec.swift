
import Foundation
import PathKit
import SwiftPackage






public struct PackageSpec: Decodable {
	
	let owner: String
	let repository: String
	let macOS: Bool
	let products: [Product]
	let dependencies: [PackageSpecDependency]?
	public let targets: [PackageTarget]
	
	enum CodingKeys: CodingKey {
		case owner
		case repository
		case products
		case dependencies
		case targets
		case macOS
	}
	public init(from decoder: Decoder) throws {
		let c = try! decoder.container(keyedBy: CodingKeys.self)
		owner = try c.decode(String.self, forKey: .owner)
		products = try c.decode([Product].self, forKey: .products)
		repository = try c.decode(String.self, forKey: .repository)
		dependencies = try c.decodeIfPresent([SwiftPackage].self, forKey: .dependencies)
		targets = try c.decode([PackageTarget].self, forKey: .targets)
		macOS = try c.decodeIfPresent(Bool.self, forKey: .macOS) ?? false
	}
	
}


public protocol PackageSpecDependency: Decodable {
	
}

extension PackageSpec {
	enum Platform: Decodable {
		case iOS(version: String)
		case macOS(version: String)
		
		enum CodingKeys: CodingKey {
			case iOS
			case macOS
		}
		enum IOSCodingKeys: CodingKey {
			case _0
		}
		enum MacOSCodingKeys: CodingKey {
			case _0
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: PackageSpec.Platform.CodingKeys.self)
			
			var allKeys = ArraySlice(container.allKeys)
			
			guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
				throw DecodingError.typeMismatch(PackageSpec.Platform.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
			}
			switch onlyKey {
			case .iOS:
				
				let nestedContainer = try container.nestedContainer(keyedBy: PackageSpec.Platform.IOSCodingKeys.self, forKey: PackageSpec.Platform.CodingKeys.iOS)
				
				self = PackageSpec.Platform.iOS(version: try nestedContainer.decode(String.self, forKey: PackageSpec.Platform.IOSCodingKeys._0))
			case .macOS:
				
				let nestedContainer = try container.nestedContainer(keyedBy: PackageSpec.Platform.MacOSCodingKeys.self, forKey: PackageSpec.Platform.CodingKeys.macOS)
				
				self = PackageSpec.Platform.macOS(version: try nestedContainer.decode(String.self, forKey: PackageSpec.Platform.MacOSCodingKeys._0))
			}
		}
		
		
	}
}

extension PackageSpec {
	
	
		
		enum Product: Decodable {
			case library(name: String, targets: [String])
			
			enum CodingKeys: CodingKey {
				case library
			}
			
			enum LibraryCodingKeys: CodingKey {
				case library
				case targets
				
			}
			
			init(from decoder: Decoder) throws {
				let container = try decoder.container(keyedBy: Product.CodingKeys.self)
				
				var allKeys = ArraySlice(container.allKeys)
				guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
					throw DecodingError.typeMismatch(Product.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
				}
				switch onlyKey {
				case .library:
					//print(container.codingPath)
					let libraryContainer = try decoder.container(keyedBy: LibraryCodingKeys.self)
					self = .library(
						name: try libraryContainer.decode(String.self, forKey: .library),
						targets: try libraryContainer.decode([String].self, forKey: .targets)
					)
					
//					let nestedContainer = try container.nestedContainer(keyedBy: Product.LibraryCodingKeys.self, forKey: Product.CodingKeys.library)
//					self = Product.library(name: try! nestedContainer.decode(String.self, forKey: Product.LibraryCodingKeys.name), targets: try nestedContainer.decode([String].self, forKey: Product.LibraryCodingKeys.targets))
				}
			}
		
		
		
	}
	
	public enum LinkerSetting: Decodable {
		case framework(value: String)
		case library(value: String)
		
		enum CodingKeys: CodingKey {
			case framework
			case library
		}
		
		public init(from decoder: Decoder) throws {
			let container: KeyedDecodingContainer<LinkerSetting.CodingKeys> = try decoder.container(keyedBy: LinkerSetting.CodingKeys.self)
			
			if container.contains(.framework) {
				self = .framework(value: try container.decode(String.self, forKey: .framework))
				
			} else if container.contains(.library){
				self = .library(value: try container.decode(String.self, forKey: .library))
				
			} else { fatalError() }
			//print(self)
		}
	}
	
	public struct BinaryTarget: PackageSpecDependency {
		
		public let path: Path
		public var localUsage: Bool
		
		public var binaryTargets: [PackageBinaryTarget] {
			if path.extension == "xcframework" { return [.init(path: path)] }
			if path.isDirectory {
				return path.createBinaryTargets()
			}
			return [.init(path: path)]
		}
		enum CodingKeys: CodingKey {
			case binary
			case local
		}
		
		public init(from decoder: Decoder) throws {
			let c = try decoder.container(keyedBy: CodingKeys.self)
			//path = try decoder.singleValueContainer().decode(Path.self)
			path = try c.decode(Path.self, forKey: .binary)
			localUsage = (try c.decodeIfPresent(Bool.self, forKey: .local)) ?? false
		}
	}
	
	public struct Target: PackageSpecDependency {
		
		public let target: String
		
		
		enum CodingKeys: CodingKey {
			case target
		}
		
		public init(from decoder: Decoder) throws {
			let c = try decoder.container(keyedBy: CodingKeys.self)
			//path = try decoder.singleValueContainer().decode(Path.self)
			target = try c.decode(String.self, forKey: .target)
		}
	}
	
	struct SwiftPackage: PackageSpecDependency {
		
		enum Version: Decodable {
			case from(version: String)
			case upToNextMajor(version: String)
			case branch(branch: String)
			case version(version: String)
			
			enum CodingKeys: CodingKey {
				case from
				case upToNextMajor
				case branch
				case version
			}
			
			init(from decoder: Decoder) throws {
				let container = try! decoder.container(keyedBy: PackageSpec.SwiftPackage.Version.CodingKeys.self)
				
				var allKeys = ArraySlice(container.allKeys)
				
				guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
					throw DecodingError.typeMismatch(PackageSpec.SwiftPackage.Version.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
				}
				print(onlyKey)
				switch onlyKey {
				case .from:
					self = .from(version: try container.decode(String.self, forKey: onlyKey))
				case .upToNextMajor:
					print(onlyKey)
					self = .upToNextMajor(version: try container.decode(String.self, forKey: onlyKey))
				case .branch:
					self = .branch(branch: try container.decode(String.self, forKey: onlyKey))
				case .version:
					self = .version(version: try container.decode(String.self, forKey: onlyKey))
				}
			}
		}
		
		var url: String?
		var path: String?
		var version: Version
		
		enum CodingKeys: CodingKey {
			case url
			case path
			case version
		}
		
		init(from decoder: Decoder) throws {
			print(try decoder.container(keyedBy: SwiftPackage.CodingKeys.self).allKeys)
			let container: KeyedDecodingContainer<SwiftPackage.CodingKeys> = try decoder.container(keyedBy: SwiftPackage.CodingKeys.self)
			self.url = try! container.decodeIfPresent(String.self, forKey: SwiftPackage.CodingKeys.url)
			self.path = try container.decodeIfPresent(String.self, forKey: SwiftPackage.CodingKeys.path)
			self.version = try! container.decode(SwiftPackage.Version.self, forKey: PackageSpec.SwiftPackage.CodingKeys.version)
			//print(url, version)
		}
	}
	
	struct PackageProduct: PackageSpecDependency {
		
		//let name: String
		let product: String
		let package: String?
		
//		var binaryTargets: [PackageBinaryTarget] {
//			if path.isDirectory {
//				return path.createBinaryTargets()
//			}
//			return [.init(path: path)]
//		}

	}
	
	public struct PackageTarget: Decodable {
		var name: String
		public var dependencies: [PackageSpecDependency]
		var resources: [String]?
		public var linkerSettings: [LinkerSetting]?
		public var custom_recipe: Bool
		
		enum CodingKeys: CodingKey {
			case target
			case dependencies
			case resources
			case linkerSettings
			case custom_recipe
		}
		public init(from decoder: Decoder) throws {
			
			let c = try decoder.container(keyedBy: CodingKeys.self)
			print(c.codingPath,c.allKeys)
			name = try c.decode(String.self, forKey: .target)
			dependencies = try c.decode([PackageSpecDependency].self, forKey: .dependencies)
			resources = try c.decodeIfPresent([String].self, forKey: .resources)
			linkerSettings = try c.decodeIfPresent([LinkerSetting].self, forKey: .linkerSettings)
			custom_recipe = try c.decodeIfPresent(Bool.self, forKey: .custom_recipe) ?? false
			
		}
		
	}
}
