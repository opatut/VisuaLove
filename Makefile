default: build run

clean:
	@[[ ! -e game.love ]] || rm game.love
	@[[ ! -e pkg ]] || rm -r pkg

build:
	@zip -0r game.love data/ visualizers/
	@cd src/ && zip -0r ../game.love *
	@cd externals/luafft/src/ && zip -0r ../../../game.love *.lua
	@cd externals/luaid3/ && zip -0r ../../game.love *.lua

run:
	@love game.love

# packaging

package-windows-x86:
	@lib/package.sh windows_x86

package-windows-x64:
	@lib/package.sh windows_x64

package-linux-x86:
	@lib/package.sh linux_x86

package-linux-x64:
	@lib/package.sh linux_x64

package-windows: package-windows-x86 package-windows-x64
package-linux: package-linux-x86 package-linux-x64
package-all: package-linux package-windows
