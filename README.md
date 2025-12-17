# Reproduction for TypeSense

`group_by` returns unexpected results when performing a multi-search. It does indeed group the results, but the `found`-property on the result set does not match the actual number of hits. In this example, `found` should be 2 (as there are 2 results), but is in fact `3`.
