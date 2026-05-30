#!/usr/bin/env python3

import argparse
import random
import bitstring


def make_vectors():
    sample_a = [random.randrange(-(2**15), 2**15) for _ in range(48)]
    sample_b = [random.randrange(-(2**15), 2**15) for _ in range(48)]

    # We shoulda called this module dot product...
    conv_out = sum(a*b for a, b in zip(sample_a, sample_b))

    return sample_a, sample_b, conv_out


def write_vector(vector, fname, nbits):
    with open(fname, "w") as f:
        for i in vector:
            line = bitstring.Bits(int=i, length=nbits).bin
            f.write(line)
            f.write("\n")


def main():
    parser = argparse.ArgumentParser(
        prog="gen_conv_vector",
        description="Generates two 48 long vectors of 16 bits for convolution test."
    )
    parser.add_argument(
        "vector_name_base",
        help=" ".join(
            (
                "Base name for output files. Outputs ARG_conv_out.memb,",
                "ARG_sample_a.memb, and ARG_sample_b.memb"
            )
        )
    )

    parsed = parser.parse_args()

    sample_a_file = parsed.vector_name_base + "_sample_a.memb"
    sample_b_file = parsed.vector_name_base + "_sample_b.memb"
    conv_out_file = parsed.vector_name_base + "_conv_out.memb"

    sample_a, sample_b, conv_out = make_vectors()
    write_vector(sample_a, sample_a_file, 16)
    write_vector(sample_b, sample_b_file, 16)
    write_vector([conv_out], conv_out_file, 38)


if __name__ == "__main__":
    main()
