#!/bin/sh
set -e

# ──────────────────────────────────────────────────────────────────────────────
# ECS タスク ID の取得
#
# ECS_CONTAINER_METADATA_URI_V4 は ECS Fargate が自動で注入する環境変数。
# ローカル開発時は未設定のため "local" にフォールバックする。
# ──────────────────────────────────────────────────────────────────────────────
if [ -n "${ECS_CONTAINER_METADATA_URI_V4}" ]; then
    # TaskARN 例: arn:aws:ecs:ap-northeast-1:123456789:task/my-cluster/a1b2c3d4e5f6
    TASK_ID=$(curl -sf "${ECS_CONTAINER_METADATA_URI_V4}/task" \
        | grep -o '"TaskARN":"[^"]*"' \
        | awk -F/ '{print $NF}' \
        | tr -d '"')
fi

# curl 成功でも JSON パース失敗などで空になる場合のフォールバック
[ -z "${TASK_ID}" ] && TASK_ID="local"

# ──────────────────────────────────────────────────────────────────────────────
# App.properties 内の <TASKID> プレースホルダをタスク ID に置換
#
# App.properties 側で以下のように記述しておく:
#   log.path=/mnt/efs/logs/<TASKID>/app.log
#   audit.log.path=/mnt/efs/audit/<TASKID>/audit.log
#
# ファイル内のすべての <TASKID> が置換されるため、複数のプロパティにも対応できる。
# また置換前に <TASKID> を含むパスのディレクトリを事前作成する。
# ──────────────────────────────────────────────────────────────────────────────
# Dockerfile で WAR を事前展開しているため catalina.sh 起動前に直接書き換えられる
PROPS_FILE="/usr/local/tomcat/webapps/ROOT/WEB-INF/classes/App.properties"
if [ -f "${PROPS_FILE}" ]; then
    # <TASKID> を含む値のパスをすべて抽出してディレクトリを作成する
    grep "<TASKID>" "${PROPS_FILE}" \
        | grep -o '=.*' \
        | sed "s|=||; s|<TASKID>|${TASK_ID}|g" \
        | sed 's|/[^/]*$||' \
        | sort -u \
        | xargs mkdir -p || true

    sed -i "s|<TASKID>|${TASK_ID}|g" "${PROPS_FILE}"
fi

exec "$@"
