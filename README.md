# ESKD – KiCad Symbol and Footprint Libraries

This repository contains the special [KiCad] schematic symbol and PCB footprint
libraries for [ESKD]. In addition to this it provides 3D models for rendering
and Mechanical CAD (MCAD) integration. The 3D models need a mechanical model
source, preferably [STEP] (a manually-modelled or script-generated file); its
[WRL] counterpart file must be obtained as a conversion from the MCAD model.

> **[ESKD] – "Einheitliches System der Konstruktionsdokumentation des [RGW]"**

For more details about [ESKD] see the README in [KiCad environment for ESKD].

[RGW]: https://de.wikipedia.org/wiki/Rat_f%C3%BCr_gegenseitige_Wirtschaftshilfe "Rat für gegenseitige Wirtschaftshilfe"
[ESKD]: https://d-nb.info/551201940 "Deutsche Netionalbibliothek"
[STEP]: https://en.wikipedia.org/wiki/ISO_10303-21 "ISO 10303-21 Clear Text Encoding of the Exchange Structure"
[WRL]: https://en.wikipedia.org/wiki/VRML "VRML file extension (Virtual Reality Modeling Language)"
[KiCad]: https://www.kicad.org/ "A Cross Platform and Open Source Electronics Design Automation Suite"
[KiCad environment for ESKD]: https://github.com/lipro-ecad/ESKD-kicad-environment

**The libraries in this repository are intended for KiCad version 6.x**

Each symbol library is stored as a `.kicad_sym` file below the `symbols`
directory.

Each footprint library is stored as a directory with the `.pretty` suffix
below the `footprints` directory. The footprint files are `.kicad_mod` files
within.

Each 3D model library is stored as a directory with the `.3dshapes` suffix
below the `3dmodels` directory. The 3D model files are `.step` and `.wrl`
files within. The 3D model library supports two file formats:

* **STEP** (`.step`) files are used for integration with MCAD software
  packages. STEP models must be 1:1 in mm, better if the model is a solid
  single object (a union of parts) for size and loading optimization. KiCad
  supports STEP file int egration and can export board and component models
  into an integrated STEP file. This file can then be imported by a MCAD
  package.
* **WRL** (`.wrl`) files must be exported from its mechanical (STEP) model
  counterpart. WRL files are used for photo-realistic rendering using KiCad's
  raytracing rendering engine. This format supports more complex material
  properties, allowing various common component materials to be accurately
  rendered.

**Preferred method to create 3D models**

The model has to be created in a mechanical program, able to generate STEP
export. The model can be created by automatic scripts or manually.
[FreeCAD](https://www.freecadweb.org/) is the preferred software because it is
open source, and anyone can rework the model for future improvements, but also
other proprietary MCAD software are allowed. In case the model is generated by
scripts, the scripts should be linked to the PR stating software and version
used to run the scripts; when the model is manually created, the MCAD source
file should be added to the PR as well as STEP file. Text is not suggested on
models because of size increasing, anyway in case of text the fonts must be
licensed free as the word. WRL models should be exported from its mechanical
counterpart and, when possible, have the suggested material properties as in
these documents:
* [WRL Material Properties]
* [WRL Illumination model]

A simple method to export a fully compliant WRL model from a mechanical STEP
model is through [KiCad StepUp](https://github.com/easyw/kicadStepUpMod). A
tutorial video can be found [here](https://youtu.be/O6vr8QFnYGw). A good
starting point to learn how to create models by script is this github repo
[kicad-3d-models-in-freecad](https://github.com/easyw/kicad-3d-models-in-freecad).
The scripts are made in Python and run in FreeCAD with
[CadQuery module](https://github.com/jmwright/cadquery-freecad-module) add-on.

[WRL Material Properties]: https://gitlab.com/kicad/libraries/kicad-packages3D/-/blob/master/Vrml_materials_doc/KiCad_3D-Viewer_component-materials-reference-list_MarioLuzeiro.pdf "KiCad￼→ KiCad Libraries → KiCad Packages3D → Repository"
[WRL Illumination model]: https://gitlab.com/kicad/libraries/kicad-packages3D/-/blob/master/Vrml_materials_doc/KiCad_3D-Viewer_Illumination_model_and_materials-MarioLuzeiro.pdf "KiCad￼→ KiCad Libraries → KiCad Packages3D → Repository"

**Contribution**

The same rules as for the original (official) KiCad libraries shall apply
to your co- and contributed work. Contribution guidelines can be found
at http://kicad.org/libraries/contribute – The library convention can
be found at http://kicad.org/libraries/klc/

As an orientation of a good library structure the official (original)
[KiCad library documentation](https://kicad.github.io/) can be helpfull:

* [Symbols](https://kicad.github.io/symbols) – Schematic symbol libraries
* [Footprints](https://kicad.github.io/footprints) – PCB footprint libraries
* [3D models](https://kicad.github.io/packages3d) – 3D model data

Other ESKD KiCad repositories are located on:

* Environment: https://github.com/lipro-ecad/ESKD-kicad-environment
* Templates: https://github.com/lipro-ecad/ESKD-kicad-templates
* Sources: https://github.com/lipro-ecad/ESKD-kicad-sources
