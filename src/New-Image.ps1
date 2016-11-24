# Script to invoke packer with the provided configuration
# Restore the cookbook dependencies -> cd cookbooks/<COOKBOOKNAME>; berks vendor ../../vendor/cookbooks
# Invoke packer -> packer build -force .\<packer_config_file.json>