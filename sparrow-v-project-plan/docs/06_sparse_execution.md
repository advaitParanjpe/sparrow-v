# Sparse Execution

## Sparse format

Version 1 targets 2:4 structured sparsity.

For every group of four dense weights, exactly two are stored as nonzero values with metadata identifying their original positions.

Example:

```text
Dense group:      [0, 7, 0, -3]
Stored values:    [7, -3]
Stored positions: [1, 3]
```

## Metadata encoding

Each 2:4 group needs two distinct indices in the range 0 to 3.

A simple encoding uses:

- 2 bits for the first index;
- 2 bits for the second index.

Invalid or duplicate index combinations must be detected in verification. The software exporter should only emit canonical valid metadata.

## Sparse dot-product behavior

Given:

- a dense activation vector;
- sparse weight values;
- position metadata;

The hardware:

1. decodes the two positions;
2. selects two activation elements from each four-element group;
3. multiplies only those selected activations by the stored values;
4. accumulates the products;
5. records skipped dense operations.

## Correctness relation

For any valid 2:4 encoded weight vector:

```text
sparse_dot(activation, values, metadata)
=
dense_dot(activation, reconstructed_dense_weights)
```

This identity must be checked in directed and randomized tests.

## Counters

The sparse unit should expose:

- sparse instructions retired;
- dense-equivalent multiply count;
- actual multiply count;
- operations skipped;
- invalid metadata detections;
- sparse-unit busy cycles.

## Software exporter

The Python tooling should:

- accept dense trained weights;
- prune them to 2:4 structure;
- optionally fine-tune or evaluate accuracy loss;
- quantize values to INT8 or INT16;
- emit packed values and metadata;
- emit a reconstructed dense representation for checking;
- generate C headers or binary blobs.

## Initial restrictions

Version 1 may require:

- groups aligned to four elements;
- exact 2:4 sparsity;
- signed integer values;
- no zero-point asymmetry;
- no arbitrary unstructured sparsity.

