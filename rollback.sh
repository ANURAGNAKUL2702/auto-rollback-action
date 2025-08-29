#!/bin/bash
set -e

echo "🚀 Auto Rollback Action Started"
echo "Rollback Type: $ROLLBACK_TYPE"

if [[ "$ROLLBACK_TYPE" == "docker" ]]; then
    echo "🔄 Rolling back Docker deployment..."
    docker pull "$REGISTRY:stable"
    docker stop myapp || true
    docker rm myapp || true
    docker run -d --name myapp "$REGISTRY:stable"
    echo "::set-output name=rollback_status::success"
    echo "::set-output name=rollback_version::stable"

elif [[ "$ROLLBACK_TYPE" == "git" ]]; then
    echo "🔄 Rolling back Git deployment..."
    git checkout "$LAST_SUCCESS_SHA"
    echo "::set-output name=rollback_status::success"
    echo "::set-output name=rollback_version::$LAST_SUCCESS_SHA"

else
    echo "❌ Invalid rollback type: $ROLLBACK_TYPE"
    exit 1
fi

if [[ ! -z "$ALERT_WEBHOOK" ]]; then
    curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\": \"⚠️ Rollback executed: $ROLLBACK_TYPE\"}" \
    $ALERT_WEBHOOK
fi

echo "✅ Auto Rollback Action Finished"
