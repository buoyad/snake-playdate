default: build

build: source
	@pdc source game.pdx

run: build
	@open game.pdx