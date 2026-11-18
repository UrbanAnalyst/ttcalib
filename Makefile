RFILE = README

all: help

doc: ## Update package documentation with `roxygen2`
	Rscript -e 'roxygen2::roxygenise()'

knith: $(RFILE)-src.Rmd ## Render README as HTML
	echo "rmarkdown::render('$(RFILE)-src.Rmd',output_file='$(RFILE).html')" | R --no-save -q

knitr: $(RFILE)-src.Rmd ## Render README as markdown
	echo "rmarkdown::render('$(RFILE)-src.Rmd',output_file='$(RFILE).md')" | R --no-save -q

open: ## Open main HTML vignette in browser
	xdg-open docs/articles/$(VIGNETTE).html &

check: ## Run `rcmdcheck`
	Rscript -e 'rcmdcheck::rcmdcheck()'

test: ## Run test suite
	Rscript -e 'testthat::test_local()'

urls: ## Apply 'urlchecker::url_update()' to update all URLs
	Rscript -e 'urlchecker::url_update()'

clean: ## Clean all junk files, including all pkgdown docs
	rm -rf *.html *.png README_cache docs/

help: ## Show this help
	@printf "Usage:\033[36m make [target]\033[0m\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
