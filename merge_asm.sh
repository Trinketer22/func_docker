#!/bin/bash

FILEA=$1
FILEB=$2

ops_file=$(mktemp)
# All ops from Asm.fif
grep Defop $FILEA > "$ops_file"
# Storing last match line
LAST_OP_B=$(grep -n Defop $FILEB | tail -n 1 | cut -d ':' -f1)
# Ops from Asm.fif not present in AsmTests.fif
NOT_MATCHING=$(grep Defop $FILEB | grep -F -v -f - "$ops_file")
rm "$ops_file"

echo "Last op:${LAST_OP_B}"

temp_file=$(mktemp)

# Append the NOT_MATCHING content to the specified line
{
    head -n "$LAST_OP_B" "$FILEB"
    echo "// Appended from Asm.fif"
	echo "$NOT_MATCHING"
	echo "// End of new instructions"
    tail -n +$((LAST_OP_B + 1)) "$FILEB"
}> "$temp_file"

mv "$temp_file" "$FILEB"
