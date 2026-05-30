#!/usr/bin/env python3

import argparse
import bitstring
import numpy as np
from scipy.io import wavfile
from scipy.signal import convolve


def build_parser():
    parser = argparse.ArgumentParser(
        prog="gen-fir-test-vectors.py",
        description="Take a wav file and FIR impulse vector, makes test vectors"
    )
    parser.add_argument(
        "wav_path",
        help="File must be encoded as signed 16 bit"
    )
    parser.add_argument("impulse_vector_path")
    parser.add_argument("sample_width", type=int)
    parser.add_argument("shift_amount", type=int)
    parser.add_argument("test_vector_base_name")
    return parser


def load_memh(filepath):
    with open(filepath, "r") as file:
        return np.array(
            [bitstring.Bits(f"0x{line}").int for line in file.readlines()],
            dtype=np.int64
        )


def write_memh(filepath, data, sample_width):
    with open(filepath, "w") as file:
        for sample in data.tolist():
            bits = bitstring.Bits(length=sample_width, int=sample)
            file.write(bits.hex)
            file.write("\n")


def read_wav(filepath):
    fs, x = wavfile.read(filepath)

    if len(x) == 1:
        return fs, x

    shape = x.shape
    shorter_dim = shape.index(min(shape))
    return fs, np.average(x, axis=shorter_dim).astype(np.int64)


def main():
    parser = build_parser()
    parsed = parser.parse_args()

    fs, x = read_wav(parsed.wav_path)
    fir_vec = load_memh(parsed.impulse_vector_path)

    convolved = convolve(x, fir_vec)
    shifted = convolved >> parsed.shift_amount

    base = parsed.test_vector_base_name
    width = parsed.sample_width

    write_memh(f"{base}-input.memh", x, width)
    write_memh(f"{base}-filtered.memh", shifted, width)
    wavfile.write(f"{base}-filtered.wav", fs, shifted.astype(np.int16))


if __name__ == "__main__":
    main()
