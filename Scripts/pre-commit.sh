#!/bin/bash

scripts/lint.sh
if [ $? -ne 0 ]; then
	exit 1
fi

# Continue with the commit
echo "🚀 All checks passed, continuing with commit..."
exit 0
