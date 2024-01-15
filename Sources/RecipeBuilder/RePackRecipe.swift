//
//  File.swift
//  
//
//  Created by CodeBuilder on 14/01/2024.
//

import Foundation
import PathKit

extension Path {
	static let projResources = Self.current + "Resources"
	static let projSitePackages = Self.projResources + "site-packages"
	
}

public struct RePackRecipe {
	
	var recipe: String
	var packageString: String
	var source: Path
	var destination: Path
	
	var dist_folder: Path { Path.current + "dist" }
	var build_folder: Path { Path.current + "build" }
	var cacheFolder: Path { Path.current + ".cache" }
	var xcframeworks: Path { dist_folder + "xcframework" }
	var dist_lib: Path { dist_folder + "lib" }
	var src_site: Path { dist_folder + "root/python3/lib/python3.11/site-packages" }
	var site_files: [Path] {
		
		return src_site.compactMap( { site_file in
			switch site_file.extension {
			case "so": return nil
			case "txt": return nil
			default: return site_file
			}
		})
	}
	// package properties
	var packageSources: Path { destination + "Sources" }
	public var packageTarget: Path { packageSources + recipe }
	
	
	public init(recipe: String, packageString: String, source: Path, destination: Path) {
		self.recipe = recipe
		self.packageString = packageString
		self.source = source
		self.destination = destination
	}
	
	public func repack() async throws {
		try? packageSources.delete()
		//if !packageTarget.exists { try packageTarget.mkpath() }
		//if !packageSources.exists { try packageSources.mkpath() }
		try (destination + "Package.swift").write(packageString, encoding: .utf8)
		
		//let targetSwiftFile = packageTarget + "\(recipe).swift"
		//try targetSwiftFile.write("", encoding: .utf8)
		
		let recipe_dist = DistFolder(root: dist_lib)
		
		let projectDist = DistFolder(root: Path.current + "dist_lib")
		
		for libA in recipe_dist.phoneOS {
			if libA.components.contains(where: { $0.hasPrefix("lib\(recipe)") }) {
				try libA.forceCopy(projectDist.phoneOS + libA.lastComponent)
			}
		}
		for libA in recipe_dist.simulatorOS {
			if libA.components.contains(where: { $0.hasPrefix("lib\(recipe)") }) {
				try libA.forceCopy(projectDist.simulatorOS + libA.lastComponent)
			}
		}
		
		
		for site_file in site_files {
			let dstFile = Path.projSitePackages + site_file.lastComponent
			switch site_file {
			case let libs where libs.extension == "libs":
				if let result = try SoLibsFile(file: libs, dist_lib: projectDist.root).output {
					try? dstFile.write(result, encoding: .utf8)
				} else {
					try? site_file.forceCopy(dstFile)
				}
			default:
				try? site_file.forceCopy(dstFile)
			}
			
		}
		
	}
}

extension RePackRecipe {
	
	struct DistFolder {
		let root: Path
		
		var phoneOS: Path { root + "iphoneos" }
		var simulatorOS: Path { root + "iphonesimulator" }
	}
}
