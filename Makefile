INK    = inkscape
SVGDS  = $(wildcard *.svg)
PDFS   = $(patsubst %.svg,%.pdf,$(SVGDS))
PNGS   = $(patsubst %.svg,%.png,$(SVGDS))

all: $(PNGS)
pdf: $(PDFS)
png: $(PNGS)

%.pdf: %.svg
	@$(INK) -D --export-type=pdf --export-filename=$@ $< >/dev/null 2>/dev/null

%.png: %.svg
	@$(INK) -D --export-png=$@ $< >/dev/null 2>/dev/null

clean:
	# @rm -f *.png
	@rm -f *.pdf
	@echo
	@echo "   Cleaned Directory!"
	@echo
