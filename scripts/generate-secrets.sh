#!/bin/bash
#
# Generate Secure Secrets for Production Deployment
# This script creates a production-secrets.yaml file with secure random passwords
#

set -e

OUTPUT_FILE="production-secrets.yaml"
BACKUP_FILE="production-secrets.yaml.backup"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Secure Secrets Generator${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if output file already exists
if [ -f "$OUTPUT_FILE" ]; then
    echo -e "${YELLOW}⚠️  WARNING: $OUTPUT_FILE already exists!${NC}"
    echo -e "${YELLOW}Creating backup as $BACKUP_FILE${NC}"
    cp "$OUTPUT_FILE" "$BACKUP_FILE"
    echo ""
fi

# Generate secure random passwords
echo -e "${BLUE}Generating secure random passwords...${NC}"
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
MYSQL_PASSWORD=$(openssl rand -base64 32)

# Create the secrets file
cat > "$OUTPUT_FILE" <<EOF
# Production Secrets
# Generated: $(date)
# ⚠️  NEVER commit this file to Git!
# ⚠️  Keep this file secure and backed up safely

mysql:
  auth:
    # MySQL root password (32-byte random)
    rootPassword: "$MYSQL_ROOT_PASSWORD"
    
    # Application database password (32-byte random)
    password: "$MYSQL_PASSWORD"
    
    # Database name and username
    database: "targets"
    username: "targets"
EOF

# Set restrictive permissions
chmod 600 "$OUTPUT_FILE"

echo -e "${GREEN}✓ Secrets file created: $OUTPUT_FILE${NC}"
echo -e "${GREEN}✓ File permissions set to 600 (owner read/write only)${NC}"
echo ""

# Display password strength
echo -e "${BLUE}Password Strength:${NC}"
echo "  Root Password Length: ${#MYSQL_ROOT_PASSWORD} characters"
echo "  App Password Length:  ${#MYSQL_PASSWORD} characters"
echo ""

# Verify .gitignore
if grep -q "$OUTPUT_FILE" .gitignore 2>/dev/null; then
    echo -e "${GREEN}✓ $OUTPUT_FILE is in .gitignore${NC}"
else
    echo -e "${YELLOW}⚠️  WARNING: $OUTPUT_FILE not found in .gitignore${NC}"
    echo -e "${YELLOW}Adding to .gitignore...${NC}"
    echo "$OUTPUT_FILE" >> .gitignore
    echo -e "${GREEN}✓ Added to .gitignore${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Next Steps${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "1. Review the generated secrets:"
echo -e "   ${GREEN}cat $OUTPUT_FILE${NC}"
echo ""
echo "2. Deploy using the secrets file:"
echo -e "   ${GREEN}helm install target-app ./helm/target-app \\${NC}"
echo -e "   ${GREEN}     -f $OUTPUT_FILE${NC}"
echo ""
echo "3. Store a backup in a secure location:"
echo -e "   ${YELLOW}# Store in password manager or encrypted vault${NC}"
echo ""
echo "4. Never commit this file to Git!"
echo ""
echo -e "${RED}⚠️  IMPORTANT SECURITY NOTES:${NC}"
echo -e "${RED}   - Keep this file secure and backed up${NC}"
echo -e "${RED}   - Never commit to version control${NC}"
echo -e "${RED}   - Store backup in encrypted vault${NC}"
echo -e "${RED}   - Rotate passwords regularly${NC}"
echo ""

# Optionally display the passwords (commented out for security)
# Uncomment if you need to see them immediately
# echo -e "${BLUE}Generated Passwords:${NC}"
# echo "Root Password: $MYSQL_ROOT_PASSWORD"
# echo "App Password:  $MYSQL_PASSWORD"
# echo ""

echo -e "${GREEN}✓ Secret generation complete!${NC}"
