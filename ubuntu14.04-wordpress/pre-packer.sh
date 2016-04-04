echo '#!/bin/bash' > scripts/install_wordpress.sh
echo '' >> scripts/install_wordpress.sh
cat scripts/web/enable_unattended_updates.sh scripts/web/make_english.sh scripts/web/setup_apache.sh scripts/web/setup_database.sh scripts/web/setup_postfix.sh scripts/web/setup_wordpress.sh >> scripts/install_wordpress.sh
chmod 755 scripts/install_wordpress.sh
