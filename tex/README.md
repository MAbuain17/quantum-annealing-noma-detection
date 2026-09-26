# EE599 thesis source

The source for the [EE599 graduation thesis](../docs/EE599-thesis.pdf) is organized around [`main.tex`](main.tex). Chapters 1–3 contain the introduction, background, methodology, and results; [`Appendix1/appendix1.tex`](Appendix1/appendix1.tex) contains the expanded QUBO coefficients for higher-order QAM. The figures used by those chapters are kept beside the source, and the bibliography is in [`References/references-fixed.bib`](References/references-fixed.bib).

## Build

Install a full TeX Live distribution with `latexmk`, `bibtex`, `pdflatex`, and the packages used in `main.tex`, `Preamble/preamble.tex`, and `EE599Thesis.cls` (including `algorithm`, `algpseudocode`, `siunitx`, `nomencl`, `appendix`, and `natbib`). From this directory:

```bash
latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex
```

This generates `main.pdf`. The [submitted thesis PDF](../docs/EE599-thesis.pdf) remains the archival project document. The source was arranged for this repository: obsolete template chapter references and unused scaffolding were removed, the bibliography's literal ampersands were escaped, and a few LaTeX syntax issues in the chapter files were corrected.

The thesis class is based on Krishna Kumar's *PhD Thesis PSnPDF* template; its MIT license is preserved in [`LICENSE`](LICENSE). The original project text, figures, and bibliography remain attributed in the thesis. For a shorter, implementation-oriented mathematical walkthrough, see the [QUBO derivation](../docs/QUBO_DERIVATION.md).
