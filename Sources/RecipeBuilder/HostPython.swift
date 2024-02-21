//
//  File.swift
//  
//
//  Created by CodeBuilder on 14/01/2024.
//

import Foundation

import PathKit

public extension URL {
	static let ZSH = URL(filePath: "/bin/zsh")
	static let hostPython = (Path.hostPython + "python3/bin/python3").url
	static let venvPython = Path.venvActivate.url
}

public extension Path {
	static let hostPython = Path.current + "hostpython"
	static let venv = Path.hostPython + "venv"
	static let venvActivate = (Path.venv + "bin/activate")
}

@discardableResult
public func buildHostPython(version: String = "3.11.6", path: Path = .hostPython) async throws -> Int32 {
	//let current = Path.current
	let openssl_path = path + "openssl"
	let tar = try await downloadPython(version: version)
	let openssl_tar = try await downloadOpenSSL(version: "1.1.1l")
	try await InstallOpenSSL(url: openssl_tar, prefix: openssl_path)
	
	let tmp = tar.parent()
	//let name = tar.lastComponentWithoutExtension
	let python_folder = path + "python3"
	//let python_folder = SYSTEM_FILES.appendingPathComponent(target_folder.rawValue).path
	let file = "Python-\(version)"
	let task = Process()
	//task.launchPath = python
	let targs = ["-c", """
		echo "path: \(tar)"
		cd \(tmp)
		tar -xf \(tar)
		rm \(tar)
		cd \(file)
		./configure -q --without-static-libpython --with-openssl=\(openssl_path.string) --prefix=\(python_folder.string)
		#make altinstall
		make -j$(nproc)
		make install
		"""]
	//task.launchPath = "/bin/zsh"
	task.executableURL = .ZSH
	task.arguments = targs
	
	//task.launch()
	try task.run()
	task.waitUntilExit()
	try tar.parent().delete()
	try openssl_tar.parent().delete()
	return task.terminationStatus
}


@discardableResult
func InstallOpenSSL(url: Path, prefix: Path) async throws -> Int32 {
	let tar = url
	let path = url.parent().string
	let file = url.lastComponentWithoutExtension.replacingOccurrences(of: ".tar", with: "")
	let targs = ["-c", """
		echo "path: \(path)"
		cd \(path)
		tar -xf \(tar)
		rm \(tar)
		cd \(file)
		./config --prefix=\(prefix.string) --openssldir=\(prefix.string) shared zlib
		make -j$(nproc)
		#make test
		make install
		cd ..
		rm -R -f \(file)
		"""]
	let task = Process()
	//task.launchPath = "/bin/zsh"
	task.executableURL = .ZSH
	task.arguments = targs
	
	try task.run()
	task.waitUntilExit()
	return task.terminationStatus
}


@discardableResult
func createVenv() async throws -> Int32 {
	let targs = ["-m", "venv", Path.venv.string]
	let task = Process()
	//task.launchPath = "/bin/zsh"
	task.executableURL = .hostPython
	task.arguments = targs
	
	try task.run()
	task.waitUntilExit()
	return task.terminationStatus
}


@discardableResult
func pipInstallVenv(pips: [String]) async throws -> Int32 {
	let script = """
	. \(Path.venvActivate)
	pip install \(pips.joined(separator: " "))
	"""
	let targs = ["-c", script]
	let task = Process()
	//task.launchPath = "/bin/zsh"
	task.executableURL = .ZSH
	task.arguments = targs
	
	try task.run()
	task.waitUntilExit()
	return task.terminationStatus
}
