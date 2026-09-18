#!/bin/bash

BACKUP_DIR="/opt/backups/openwebui"
VOLUME_NAME="open-webui-data"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/openwebui_backup_$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

# 使用临时容器备份数据卷
docker run --rm \
  -v $VOLUME_NAME:/source:ro \
  -v $BACKUP_DIR:/backup \
  alpine tar czf "$BACKUP_DIR/openwebui_backup_$DATE.tar.gz" -C /source .

# 删除7天前的备份
find "$BACKUP_DIR" -name "openwebui_backup_*.tar.gz" -mtime +7 -delete

echo "备份完成: $BACKUP_FILE"
