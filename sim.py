#!/usr/bin/env python3

# FIXME dih: Properly log all print statements later

# FIXME dih: Dump iverilog logs as text files (would need to use
# subprocess.Popen to capture and print at the same time)

# TODO list
# - README.md file for my sim script
#
# - Setuptools?
#
# - plus args
#
# - regression feature, maybe through another script that calls this
#   figure out how to handle multiple processes to make faster
#
# - macro to help make outputing waves in a different directory easier
#   although this may be better suited as a library file
#
# - Don't separate fpga and verif? In the end, what's stopping you from writing
#   a synthesizable testbench?

import argparse
import os
import subprocess
import errno
import sys
import glob


# Lists for reasons
IVERILOG = ["iverilog"]
VVP = ["vvp"]
VVP_POST = ["-fst"]

IVERILOG_BASE_FLAGS = [
    "-g2012",
    "-Wall",
    "-Wno-sensitivity-entire-vector",
    "-Wno-sensitivity-entire-array",
    "-Y",
    ".sv",
]

VIVADO = ["vivado"]
VIVADO_FLAGS = ["-mode", "batch", "-source"]
VIVADO_SCRIPT_NAMES = {
    "VIVADO_BUILD_SCRIPT": "build.tcl",
    "VIVADO_WRITE_SCRIPT": "program.tcl",
}


def print_header(header, frame_char="#", frame_width=2, header_width=40):
    """
    Print a framed header.
    """
    header_text = header.center(header_width)
    side_boarder = frame_width * frame_char

    header_line = f"{side_boarder} {header_text} {side_boarder}"
    frame_line = len(header_line) * frame_char

    print(frame_line, header_line, frame_line, sep="\n")
    print("")


def make_absolute_paths(path_list):
    """
    Convert list of paths into absolute paths.
    """
    return [os.path.abspath(x) for x in path_list]


def make_parser():
    """
    Generate parser object.
    """
    parser = argparse.ArgumentParser(
        prog="sim.py",
        description=(
            " ".join(
                (
                    "Compile and run testbench/Synthesize HDL for FPGA.",
                    "Results of compilation and logs are placed in a build directory.",
                    "A testbench is defined and an iverilog command file called"
                    "testbench.cf specifying how files should be included.",
                    "\n\n",
                    "Script always defines the macros SIMULATION",
                    "TESTBENCH_ROOT=testbench/root/path. This is meant for loading vectors.",
                )
            )
        ),
    )
    parser.add_argument(
        "testbench_path",
        help=" ".join(
            ("Path to testbench, e.g. verif/my_module/",
             "Also path for synthesis root, e.g. fpga/my_module")
        )
    )
    parser.add_argument("--hdl-root", help="Path to root of HDL", default="./hdl/")
    parser.add_argument(
        "--build-dir",
        default="./build-hdl/",
        help="Directory to compile HDL into simulation binary.",
    )
    parser.add_argument(
        "--sim-name",
        help=" ".join(
            (
                "Name of compiled simulation file. If not specified,",
                "defaults to the name of the testbench file.",
            )
        ),
    )
    parser.add_argument(
        "-b",
        "--build-testbench",
        action="store_true",
        help="Compile but do not run a testbench.",
    )
    parser.add_argument(
        "-r",
        "--run-testbench",
        action="store_true",
        help="Run an already built testbench. If not already built, build it first.",
    )
    parser.add_argument(
        "-s",
        "--synthesize",
        action="store_true",
        help="Synthesize an FPGA module. Cannot be run in the same command as a simulation.",
    )
    parser.add_argument(
        "-w",
        "--write-bitstream",
        nargs="?",
        const="vivado",
        default="no-flash",
        type=str,
        help="Write an FPGA bitstream to hardware."
    )
    parser.add_argument(
        "-p",
        "--plus-args",
        action="extend",
        nargs="+",
        default=[],
        help="+args to pass to testbench during run.",
    )
    parser.add_argument(
        "-D",
        "--define-macro",
        help="Define macro in top level. Passes arguments to iverilog with -D",
        action="append",
        # Might need to make it so this gets overridden down the road if this
        # is extended to synthesis
        default=["SIMULATION"],
    )
    parser.add_argument(
        "--testbench-name",
        default="testbench.cf",
        help="Name of testbench command file",
    )
    return parser


def compile_testbench(parsed, sim_env):
    """
    Compile testbench based on arguments with iverilog.
    """
    defines = parsed.define_macro + [f"TESTBENCH_ROOT=\"{sim_env['TESTBENCH_ROOT']}\""]
    defines = [f"-D{x}" for x in defines]
    testbench_file_path = os.path.join(sim_env["TESTBENCH_ROOT"], parsed.testbench_name)

    command = (
        IVERILOG
        + IVERILOG_BASE_FLAGS
        + defines
        + ["-c", testbench_file_path]
        + ["-o", sim_env["TESTBENCH_NAME"]]
    )

    print_header("Compiling testbench:")

    print(" ".join(command))
    compile_process = subprocess.run(command, env=sim_env, cwd=sim_env["BUILD_DIR"])

    if compile_process.returncode != 0:
        print("Compilation failed.")
        sys.exit(-1)

    print_header("End of Compilation")


def simulate_testbench(parsed, sim_env):
    """
    Simulate testbench with vvp.
    """
    print_header("Begin Simulation")

    compiled_testbench = os.path.join(sim_env["BUILD_DIR"], sim_env["TESTBENCH_NAME"])
    if not os.path.exists(compiled_testbench):
        print("Testbench is not compiled. Try running sim.py with -b")
        # raise FileNotFoundError("Testbench is not compiled.")
        sys.exit(errno.ENOENT)

    command = VVP + [sim_env["TESTBENCH_NAME"]] + VVP_POST
    print(f"Running testbench {sim_env['TESTBENCH_NAME']}")
    subprocess.run(command, env=sim_env, cwd=sim_env["BUILD_DIR"])
    print_header("End of Simulation")


def synthesize_vivado(parsed, sim_env):
    """
    Synthesize an FPGA bitstream with Vivado
    """
    print_header("Begin Synthesize HDL to Bitstream")

    # Not sure if including all .sv files is wise, but should be fine.
    hdl_pattern = os.path.join(sim_env["HDL_ROOT"], "*.sv")
    hdl_sources = glob.glob(hdl_pattern)

    fpga_pattern = os.path.join(sim_env["SYNTHESIS_ROOT"], "*.sv")
    hdl_sources += glob.glob(fpga_pattern)


    constraint_file_pattern = os.path.join(sim_env["SYNTHESIS_ROOT"], "*.xdc")
    constraint_file = glob.glob(constraint_file_pattern)[0]

    # Update the environment for Vivado, yes I know it mutates it
    sim_env["SYNTH_HDL_SOURCES"] = " ".join(hdl_sources)
    sim_env["SYNTH_XDC_FILE"] = constraint_file
    sim_env["SYNTH_TOP_MODULE"] = sim_env["SYNTHESIS_NAME"]

    command = VIVADO + VIVADO_FLAGS + [sim_env["VIVADO_BUILD_SCRIPT"]]
    print(" ".join(command))

    process = subprocess.run(command, env=sim_env, cwd=sim_env["BUILD_DIR"])
    if process.returncode != 0:
        print("Failed to synthesize HDL.")
        exit(-1)

    print_header("End Synthesize HDL")


def program_vivado(parsed, sim_env):
    """
    Program a design to an FPGA via Vivado.
    """
    print_header("Begin FPGA Vivado Program")

    fpga_bitstream = os.path.abspath(
        os.path.join(
            sim_env["BUILD_DIR"],
            sim_env["SYNTHESIS_NAME"]+".bit"
        )
    )

    if not os.path.exists(fpga_bitstream):
        print("Design not synthesized. Try running sim.py with -s")
        # raise FileNotFoundError("Testbench is not compiled.")
        sys.exit(errno.ENOENT)

    sim_env["SYNTH_BITSTREAM"] = fpga_bitstream

    command = VIVADO + VIVADO_FLAGS + [sim_env["VIVADO_WRITE_SCRIPT"]]
    process = subprocess.run(command, env=sim_env, cwd=sim_env["BUILD_DIR"])
    if process.returncode != 0:
        print("Failed to program FPGA.")
        exit(-1)

    print_header("End FPGA Vivado Program")


def program_digilent(parsed, sim_env):
    """
    Program an FPGA with Digilent
    """
    # Hardcoded board, yes. It's fine for now.
    base_command = "djtgcfg prog -d CmodA7 -i 0 -f".split()

    print_header("Begin FPGA Digilent Program")

    fpga_bitstream = os.path.abspath(
        os.path.join(
            sim_env["BUILD_DIR"],
            sim_env["SYNTHESIS_NAME"]+".bit"
        )
    )

    if not os.path.exists(fpga_bitstream):
        print("Design not synthesized. Try running sim.py with -s")
        # raise FileNotFoundError("Testbench is not compiled.")
        sys.exit(errno.ENOENT)

    command = base_command + [fpga_bitstream]
    process = subprocess.run(command, env=sim_env, cwd=sim_env["BUILD_DIR"])
    if process.returncode != 0:
        print("Failed to program FPGA.")
        exit(-1)

    print_header("End FPGA Digilent Program")


def main():
    parser = make_parser()
    parsed = parser.parse_args()

    # Setup environment variables, all of these might be useful in command file
    # or verilog testbench.
    sim_env = os.environ.copy()
    sim_env["HDL_ROOT"] = os.path.abspath(parsed.hdl_root)

    # Equivalent for how script is called
    sim_env["TESTBENCH_ROOT"] = os.path.abspath(parsed.testbench_path)
    sim_env["SYNTHESIS_ROOT"] = sim_env["TESTBENCH_ROOT"]

    sim_env["BUILD_DIR"] = os.path.abspath(parsed.build_dir)
    # Name of testbench/fpga module, also used as the name of the binary file
    sim_env["TESTBENCH_NAME"] = os.path.basename(sim_env["TESTBENCH_ROOT"])
    sim_env["SYNTHESIS_NAME"] = sim_env["TESTBENCH_NAME"]

    # Vivado
    for key, val in VIVADO_SCRIPT_NAMES.items():
        script_path = os.path.abspath(val)
        sim_env[key] = script_path

    # Make build dir
    print_header(f"Creating build directory {sim_env['BUILD_DIR']}")
    try:
        os.mkdir(sim_env["BUILD_DIR"])
    except FileExistsError:
        print("Skipping, build dir exists")
    print_header("Made build directory")

    # Do actions
    if parsed.synthesize: # Synthesize
        synthesize_vivado(parsed, sim_env)

    if parsed.write_bitstream == "vivado":
        program_vivado(parsed, sim_env)
    elif parsed.write_bitstream == "digilent":
        program_digilent(parsed, sim_env);

    if parsed.build_testbench:
        compile_testbench(parsed, sim_env)

    if parsed.run_testbench:
        simulate_testbench(parsed, sim_env)


if __name__ == "__main__":
    main()
