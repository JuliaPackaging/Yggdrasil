"""
Fix: parsec_param_enable_mpi_overtake must be declared regardless of PARSEC_HAVE_MPI_OVERTAKE.
The variable is used in '#if !defined(PARSEC_HAVE_MPI_OVERTAKE)' blocks, but declared
only inside '#if defined(PARSEC_HAVE_MPI_OVERTAKE)'. Add an #else branch to the declaration.
"""
import sys, os

src_path = os.path.join(
    os.environ.get("WORKSPACE", ""), "srcdir", "parsec",
    "parsec", "parsec_mpi_funnelled.c")
if not os.path.exists(src_path):
    src_path = os.path.join("parsec", "parsec_mpi_funnelled.c")

with open(src_path) as f:
    content = f.read()

old = (
    "#if defined(PARSEC_HAVE_MPI_OVERTAKE)\n"
    "static int parsec_param_enable_mpi_overtake = 1;\n"
    "#endif"
)
new = (
    "#if defined(PARSEC_HAVE_MPI_OVERTAKE)\n"
    "static int parsec_param_enable_mpi_overtake = 1;\n"
    "#else\n"
    "static int parsec_param_enable_mpi_overtake = 0;\n"
    "#endif"
)

if old not in content:
    print("ERROR: Could not find declaration to patch!", file=sys.stderr)
    sys.exit(1)

content = content.replace(old, new, 1)

with open(src_path, "w") as f:
    f.write(content)

print("parsec_mpi_funnelled.c patched: unconditional declaration of parsec_param_enable_mpi_overtake.")
