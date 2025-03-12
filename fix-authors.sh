#!/bin/bash

# Check if git-filter-repo is installed
if ! command -v git-filter-repo &> /dev/null; then
    echo "Installing git-filter-repo..."
    # Create a temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Clone the git-filter-repo repository
    git clone https://github.com/newren/git-filter-repo.git > /dev/null 2>&1
    
    # Install git-filter-repo
    cd git-filter-repo
    sudo cp git-filter-repo /usr/local/bin/
    
    # Clean up
    cd ../..
    rm -rf "$TEMP_DIR"
    
    echo "git-filter-repo installed successfully."
fi

# Create a temporary mailmap file
cat > .mailmap << EOF
Wilson Bilkovich <wilsonb@gmail.com> Wilson Bilkovich (aider) <wilsonb@gmail.com>
EOF

# Run git-filter-repo to fix author names
git filter-repo --use-mailmap --force

# Clean up
rm .mailmap

echo "Author names have been fixed. All instances of 'Wilson Bilkovich (aider)' have been changed to 'Wilson Bilkovich'."
