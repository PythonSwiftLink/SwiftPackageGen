#from cookiecutter.main import cookiecutter
from os.path import join, abspath
from os import pardir, getcwd
import sys

if not len(sys.argv) >= 3: 
    exit(-1)

version = sys.argv[1]
sha = sys.argv[2]



template0 = """
class Swiftpackagegen < Formula
  desc ""
  homepage ""

  url "https://github.com/PythonSwiftLink/SwiftPackageGen/releases/download/{version}/SwiftPackageGen.tar.gz"
  version "{version}"
  sha256 "{sha}"
  license ""

  def install
    bin.install "SwiftPackageGen"
    end

  test do
    system "false"
  end
end
"""

template0 = """
class Swiftpackagegen{version_name} < Formula
  depends_on "xcodegen"
  desc ""
  homepage ""

  url "https://github.com/PythonSwiftLink/SwiftPackageGen/releases/download/{version}/SwiftPackageGen.tar.gz"
  version "{version}"
  sha256 "{sha}"
  license ""

  def install
    bin.install "SwiftPackageGen"
    end

  test do
    system "false"
  end
end
"""

# template_dir = "https://github.com/PythonSwiftLink/BrewFormulaCookie.git"

# context = {
#     "version": version,
#     "name_version": version.replace(".",""),
#     "sha": sha
# }

formula_lastest = template0.format(version=version, version_name="", sha=sha)

formula_version = template0.format(version=version, version_name=f'AT{version.replace(".","")}', sha=sha)

with open("homebrew_formula/swiftpackagegen.rb", "w") as f:
    f.write(formula_lastest)

with open(f"homebrew_formula/swiftpackagegen@{version}.rb", "w") as f:
    f.write(formula_version)
