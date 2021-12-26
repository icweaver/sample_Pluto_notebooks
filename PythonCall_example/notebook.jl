### A Pluto.jl notebook ###
# v0.17.4

using Markdown
using InteractiveUtils

# ╔═╡ 22b67cb0-6687-11ec-1868-bb216a9703f4
begin
	import Pkg
	Pkg.activate(Base.current_project())
	
	using PythonCall, CondaPkg, PlutoUI
end

# ╔═╡ f150770d-cbcd-4eda-a0a5-b759a21f5b9b
md"""
# A new way to interface with 🐍

`PythonCall.jl` vs. `PyCall.jl`

$(TableOfContents())
"""

# ╔═╡ 30181f53-97e2-4d21-83d2-9394ef64aba2
md"""
## Trying it out
To see how we can start using this package, let's start by creating some simple Python objects:
"""

# ╔═╡ b1f1706d-da3b-48ae-bed1-4f5fb9e95726
py_list = @pyeval "[1, 2, 3]"

# ╔═╡ 46e9b23c-07d2-49d9-af7a-6fe094b8e0be
y = 9

# ╔═╡ fa184670-718c-4e68-8e23-fe6e72a651c5
py_dict = @pyeval "{'one': 1, 'two': 2, 'three': 3}"

# ╔═╡ 53b89008-8ac0-4f20-955d-1d875530f121
py_range = @pyeval "range(0, 10, 2)"

# ╔═╡ 81a0a61d-0ff8-4610-915b-3f32a2742f5d
md"""
The `@pyeval` macro behaves like Python's [`eval`](https://docs.python.org/3/library/functions.html#eval) and evaluates whatever Python expression (written as a string literal or `cmd`) is passed to it. The returned objects can participate in the usual Python methods now:
"""

# ╔═╡ 15b2d0ab-bc1a-435a-9557-99537d117d91
py_list.append(4); py_list

# ╔═╡ ffa07e57-7797-4000-8be4-a166895bcc54
py_dict["three"]

# ╔═╡ 5e0919d8-0a02-46fc-92fe-0a5e40d1708c
py_range[0] # Python's zero-based indexing is also automatically respected

# ╔═╡ 3359adff-8eb5-4911-a914-047ecf3663fe
md"""
PythonCall.jl also provides a function version of `@pyeval` if we would like to do things like string interpolation first:
"""

# ╔═╡ 6be1822a-d905-4de9-8345-4e160e53ea64
let
	four = 4
	pyeval("[1, 2, 3, $four]", Main)
end

# ╔═╡ 0b3322b5-cd15-49d9-a446-35224a4b7637
md"""
!!! tip
	We recommend passing strings ("") instead of cmds (\`\`) to play nice with Pluto's `ExpressionExplorer`
 
	Related issue?: <https://github.com/fonsp/Pluto.jl/issues/961>
"""

# ╔═╡ a7e24a65-cfa8-4e03-9664-f8f424324917
md"""
To a certain extent, Julia's functions can also operate on these objects automatically:
"""

# ╔═╡ 1e94e185-af8c-4796-9358-6a2c15c7fd43
py_range |> sum

# ╔═╡ 07c516fe-97d1-40ad-bd79-a9c3c379e234
md"""
but it is probably best to avoid mixing and matching too much if possible to avoid things like this:
"""

# ╔═╡ b810a02b-8329-4f51-8cfc-c6920ad1cf5d
py_range |> collect

# ╔═╡ 40cb6860-7ac6-40ca-8b1f-30360fd6aef7
md"""
As an alternative, `PythonCall` makes it very easy to convert these objects to their native Julia counterparts with the `@pyconvert` macro:
"""

# ╔═╡ 57686014-99e8-4733-8f1d-ba80306b9da9
(@pyconvert StepRange py_range) |> collect

# ╔═╡ 1360029e-76f3-468a-9b2f-d27482bbc525
pyconvert(StepRange, py_range) |> collect

# ╔═╡ e9e6c4e0-6834-4b6b-ac20-ff722f9a5cd9
md"""
## Installing packages
"""

# ╔═╡ 61944f41-4e96-472d-bd0b-9aa3f69dfc4f
md"""
We can add Python packages using `CondaPkg` in the following way:
"""

# ╔═╡ 0bf45621-7776-403e-b3da-5311a5c30e20
begin
	CondaPkg.add("lightkurve")
	CondaPkg.resolve()
end

# ╔═╡ a159c36c-83c8-460e-a7e2-e85c7df8d9da
@py begin
	import lightkurve as lk
	import numpy as np
end

# ╔═╡ 655674de-56c1-4386-8fda-aa5c95b6271f
@with_terminal begin
	CondaPkg.status()
end

# ╔═╡ c47c1968-828a-4422-997d-39c91b16d176
x = np.linspace(1, 3, 10)

# ╔═╡ d4e53c87-7f43-4ac8-9c85-0dd2afc4a5c8
md"""
So `PythonCall` returns its own Julia type that correspond to the Python object used. The list of corresponding types live here
"""

# ╔═╡ Cell order:
# ╟─f150770d-cbcd-4eda-a0a5-b759a21f5b9b
# ╟─30181f53-97e2-4d21-83d2-9394ef64aba2
# ╠═b1f1706d-da3b-48ae-bed1-4f5fb9e95726
# ╠═46e9b23c-07d2-49d9-af7a-6fe094b8e0be
# ╠═fa184670-718c-4e68-8e23-fe6e72a651c5
# ╠═53b89008-8ac0-4f20-955d-1d875530f121
# ╟─81a0a61d-0ff8-4610-915b-3f32a2742f5d
# ╠═15b2d0ab-bc1a-435a-9557-99537d117d91
# ╠═ffa07e57-7797-4000-8be4-a166895bcc54
# ╠═5e0919d8-0a02-46fc-92fe-0a5e40d1708c
# ╠═3359adff-8eb5-4911-a914-047ecf3663fe
# ╠═6be1822a-d905-4de9-8345-4e160e53ea64
# ╟─0b3322b5-cd15-49d9-a446-35224a4b7637
# ╟─a7e24a65-cfa8-4e03-9664-f8f424324917
# ╠═1e94e185-af8c-4796-9358-6a2c15c7fd43
# ╠═07c516fe-97d1-40ad-bd79-a9c3c379e234
# ╠═b810a02b-8329-4f51-8cfc-c6920ad1cf5d
# ╟─40cb6860-7ac6-40ca-8b1f-30360fd6aef7
# ╠═57686014-99e8-4733-8f1d-ba80306b9da9
# ╠═1360029e-76f3-468a-9b2f-d27482bbc525
# ╠═e9e6c4e0-6834-4b6b-ac20-ff722f9a5cd9
# ╟─61944f41-4e96-472d-bd0b-9aa3f69dfc4f
# ╠═0bf45621-7776-403e-b3da-5311a5c30e20
# ╠═a159c36c-83c8-460e-a7e2-e85c7df8d9da
# ╠═655674de-56c1-4386-8fda-aa5c95b6271f
# ╠═c47c1968-828a-4422-997d-39c91b16d176
# ╠═d4e53c87-7f43-4ac8-9c85-0dd2afc4a5c8
# ╠═22b67cb0-6687-11ec-1868-bb216a9703f4
