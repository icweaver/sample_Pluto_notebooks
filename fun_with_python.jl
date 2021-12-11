### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# ╔═╡ ab57c20d-542c-4079-8d7d-21e523f7bdaa
begin
	using PyCall
	
	# The usual way to install things is with `conda`
	const Conda = PyCall.Conda
	const env = :transits
	Conda.add("lightkurve", env, channel="conda-forge")
	
	# But we can use `pip` too if we want!
	Conda.pip_interop(true, env)
	Conda.pip("install", "batman-package", env)
end

# ╔═╡ bddf0d78-c44a-41aa-a735-0b9ce5196d76
using PyPlot

# ╔═╡ 11a74633-c07a-467c-943a-475e16b51205
using PlutoUI

# ╔═╡ 7c4c556c-7399-4585-a9c4-428734b9a9b2
md"""
# Fun with 🐍

Interfacing with Python is seamless, thanks to [`PyCall.jl`](https://github.com/JuliaPy/PyCall.jl). There is [*a bunch*](https://github.com/JuliaPy/PyCall.jl#readme) that we can configure here, but in this notebook we will focus on using self-contained environments to explore interfacing with Python.

$(TableOfContents())
"""

# ╔═╡ 5b1b5ad1-b275-449b-b4bd-f0105cd17830
md"""
## Setting up an enviroment for the first time

`PyCall.jl` automatically comes with `Conda.jl`, which uses `conda` for package installation and environment management. By default, everything is installed to a global environment in `~/.julia/conda/3`. We are responsible scientists though, and will create our own environment by passing it to `Conda.add` before installing our packages:
"""

# ╔═╡ ca74eea8-26de-4ecf-9e08-75658a3ae56a
md"""!!! note
	We used the [`Conda.jl`](https://github.com/JuliaPy/Conda.jl) package that is automatically exported with `PyCall.jl` to install `batman` with `pip`, but we could have installed it from the `conda-forge` channel as well:

	```julia
	Conda.add("batman-package"; channel="conda-forge")
	```
"""

# ╔═╡ 573962a7-ddfd-4c53-9c16-9ff1175065a2
md"""
We can use the equivalent `conda list` command to verify that the packages we wanted have been installed to our environment:
"""

# ╔═╡ 2bf423ab-3b20-4952-9341-f3b3b23092aa
with_terminal() do
	Conda.list(env)
end

# ╔═╡ f9bc4f88-4963-4328-9ad7-244e0b8ab2ea
md"""
Great, let's start using them!
"""

# ╔═╡ 793a51ba-f589-42f4-b562-bfcc0291243d
md"""
## Working with user scripts

One common workflow in `PyCall.jl` is to write Python code verbatim in a string, and then execute that string using the Python interpreter. This is accomplished with the exported string macros `py"<script here>"` and `py\"""<script here>\"""` for single and multi-line Python scripts, respectively (technically [eval](https://docs.python.org/3/library/functions.html#eval) and [exec](https://docs.python.org/3/library/functions.html#exec)). When possible, `PyCall.jl` will even convert the Python objects to their native Julia equivalents!
"""

# ╔═╡ 89f64c88-ed8f-47c6-b500-ab6898f10459
d = py"{'a': 1, 'b': 2, 'c': 3}"

# ╔═╡ 2dd9d06d-a5a0-476f-8c83-8bfae12d5594
py"[i for i in range(4)]"

# ╔═╡ bc08bcd5-46a8-40ae-af8c-ff865a9a1543
md"""
A very useful pattern is to write Python functions inside of the multi-line `py` strings, and then wrap it inside of a Julia function:
"""

# ╔═╡ c6b96207-f98d-4bdb-a6be-8d146f0fdeca
begin
	py"""
	def dict_sum_py(d):
		sum = 0
		for (k, v) in d.items():
			sum += v
		return sum
	"""
	dict_sum(d) = py"dict_sum_py"(d)
end

# ╔═╡ 5ed4bbd4-08ec-41bc-abdd-42c42d24daff
md"""
Now this function -- that was originally defined in Python -- can use Pluto's reactivity, just like any other Julia function 🌈
"""

# ╔═╡ 4595f4f8-3aad-4095-845f-74cd9922c22b
dict_sum(d)

# ╔═╡ 2ed0268e-fb43-4ad3-bcbd-7f66ac796f7f
md"""
!!! tip

	Try modifying `d` to see this for yourself!
"""

# ╔═╡ 5bd935db-1404-4171-9355-fadf8c9f5ae3
md"""
Importing packages also work exactly as we would expect. Let's see this in action by using `numpy` to define a toy function `neg_norm` that takes the inputs ``(x, y)`` and returns the negative of its vector norm:

```math
	-\sqrt{x^2 + y^2} \quad.
```
"""

# ╔═╡ 2be60363-fed7-4146-ada6-bb287ab94678
begin
	py"""
	import numpy as np
	
	def neg_norm(x, y):
		return -np.linalg.norm([x, y])
	"""
	neg_norm(x, y) = py"neg_norm"(x, y)
end

# ╔═╡ bb7aaa9e-1b22-4706-a582-dcb090c85b99
neg_norm(3, 4)

# ╔═╡ 8d512b4c-a0ad-453f-8b51-c09cc63c6a49
md"""
Package imports should persist in other cells as well:
"""

# ╔═╡ 3c727a15-b417-4115-acea-203a402deb12
begin
	py"""
	def neg_norm2(x, y):
		return -2.0*np.linalg.norm([x, y])
	"""
	neg_norm2(x, y) = py"neg_norm2"(x, y)
end

# ╔═╡ 0fd5457a-e541-4b10-9df9-735c6ecb01db
neg_norm2(3, 4)

# ╔═╡ 557b7c94-4bc6-4cb0-ac90-bc863ea729d8
md"""
Looks good!
"""

# ╔═╡ 7c1aec75-4907-4ad4-b6d5-88a36f044646
md"""
## Working with libraries

Another powerful feature of `PyCall.jl` is `pyimport`
"""

# ╔═╡ 04b5e2f6-ae95-40eb-87e6-0e45dbf1aed3
lk = pyimport("lightkurve")

# ╔═╡ f7500f47-28b9-47b5-82cc-68fc4d53c888
pixelfile = lk.search_targetpixelfile("KIC 8462852", quarter=16).download()

# ╔═╡ f15eed54-2dbe-4e20-b43c-57566ba8a153
pixelfile.plot(); show()

# ╔═╡ e442eab3-ba32-433d-8cfd-3ba2160b94ba
lc = pixelfile.to_lightcurve()

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
PyPlot = "d330b81b-6aea-500a-939a-2ce795aea3ee"

[compat]
PlutoUI = "~0.7.22"
PyCall = "~1.92.5"
PyPlot = "~2.10.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.0"
manifest_format = "2.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "abb72771fd8895a7ebd83d5632dc4b989b022b5b"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.Conda]]
deps = ["Downloads", "JSON", "VersionParsing"]
git-tree-sha1 = "6cdc8832ba11c7695f494c9d9a1c31e90959ce0f"
uuid = "8f4d0f93-b110-5947-807f-2305c1781a2d"
version = "1.6.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "ae4bbcadb2906ccc085cf52ac286dc1377dceccc"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.1.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "565564f615ba8c4e4f40f5d29784aa50a8f7bbaf"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.22"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.PyCall]]
deps = ["Conda", "Dates", "Libdl", "LinearAlgebra", "MacroTools", "Serialization", "VersionParsing"]
git-tree-sha1 = "4ba3651d33ef76e24fef6a598b63ffd1c5e1cd17"
uuid = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
version = "1.92.5"

[[deps.PyPlot]]
deps = ["Colors", "LaTeXStrings", "PyCall", "Sockets", "Test", "VersionParsing"]
git-tree-sha1 = "14c1b795b9d764e1784713941e787e1384268103"
uuid = "d330b81b-6aea-500a-939a-2ce795aea3ee"
version = "2.10.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.VersionParsing]]
git-tree-sha1 = "e575cf85535c7c3292b4d89d89cc29e8c3098e47"
uuid = "81def892-9a0e-5fdd-b105-ffc91e053289"
version = "1.2.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─7c4c556c-7399-4585-a9c4-428734b9a9b2
# ╟─5b1b5ad1-b275-449b-b4bd-f0105cd17830
# ╠═ab57c20d-542c-4079-8d7d-21e523f7bdaa
# ╟─ca74eea8-26de-4ecf-9e08-75658a3ae56a
# ╟─573962a7-ddfd-4c53-9c16-9ff1175065a2
# ╠═2bf423ab-3b20-4952-9341-f3b3b23092aa
# ╟─f9bc4f88-4963-4328-9ad7-244e0b8ab2ea
# ╟─793a51ba-f589-42f4-b562-bfcc0291243d
# ╠═89f64c88-ed8f-47c6-b500-ab6898f10459
# ╠═2dd9d06d-a5a0-476f-8c83-8bfae12d5594
# ╟─bc08bcd5-46a8-40ae-af8c-ff865a9a1543
# ╠═c6b96207-f98d-4bdb-a6be-8d146f0fdeca
# ╟─5ed4bbd4-08ec-41bc-abdd-42c42d24daff
# ╠═4595f4f8-3aad-4095-845f-74cd9922c22b
# ╟─2ed0268e-fb43-4ad3-bcbd-7f66ac796f7f
# ╟─5bd935db-1404-4171-9355-fadf8c9f5ae3
# ╠═2be60363-fed7-4146-ada6-bb287ab94678
# ╠═bb7aaa9e-1b22-4706-a582-dcb090c85b99
# ╟─8d512b4c-a0ad-453f-8b51-c09cc63c6a49
# ╠═3c727a15-b417-4115-acea-203a402deb12
# ╠═0fd5457a-e541-4b10-9df9-735c6ecb01db
# ╟─557b7c94-4bc6-4cb0-ac90-bc863ea729d8
# ╠═7c1aec75-4907-4ad4-b6d5-88a36f044646
# ╠═04b5e2f6-ae95-40eb-87e6-0e45dbf1aed3
# ╠═f7500f47-28b9-47b5-82cc-68fc4d53c888
# ╠═bddf0d78-c44a-41aa-a735-0b9ce5196d76
# ╠═f15eed54-2dbe-4e20-b43c-57566ba8a153
# ╠═e442eab3-ba32-433d-8cfd-3ba2160b94ba
# ╟─11a74633-c07a-467c-943a-475e16b51205
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
