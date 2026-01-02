import json
import boto3
import os
from datetime import datetime

# 環境変数から設定を取得
DB_INSTANCE_IDENTIFIER = os.environ.get('DB_INSTANCE_IDENTIFIER')
S3_BUCKET_NAME = os.environ.get('S3_BUCKET_NAME')
IAM_ROLE_ARN = os.environ.get('IAM_ROLE_ARN')
KMS_KEY_ID = os.environ.get('KMS_KEY_ID')

rds_client = boto3.client('rds')

def get_latest_snapshot(db_instance_identifier):
    """
    指定されたDBインスタンスの最新のスナップショット（自動・手動問わず）を取得
    """
    try:
        response = rds_client.describe_db_snapshots(
            DBInstanceIdentifier=db_instance_identifier,
            MaxRecords=7
        )

        snapshots = response.get('DBSnapshots', [])

        if not snapshots:
            raise Exception(f"No snapshots found for DB instance: {db_instance_identifier}")

        # スナップショット作成日時でソートして最新のものを取得
        latest_snapshot = sorted(
            snapshots,
            key=lambda x: x['SnapshotCreateTime'],
            reverse=True
        )[0]

        return latest_snapshot['DBSnapshotArn']

    except Exception as e:
        print(f"Error getting latest snapshot: {str(e)}")
        raise

def lambda_handler(event, context):
    try:
        # 最新のスナップショットARNを取得
        snapshot_arn = get_latest_snapshot(DB_INSTANCE_IDENTIFIER)
        print(f"Latest snapshot ARN: {snapshot_arn}")

        # エクスポートタスクの識別子を生成
        export_task_identifier = "ruby-getting-started-mysql-" + datetime.now().strftime("%Y%m%d%H%M%S")

        # RDSスナップショットをS3にエクスポート
        response = rds_client.start_export_task(
            ExportTaskIdentifier=export_task_identifier,
            SourceArn=snapshot_arn,
            S3BucketName=S3_BUCKET_NAME,
            IamRoleArn=IAM_ROLE_ARN,
            KmsKeyId=KMS_KEY_ID
        )

        print(f"Export task started: {export_task_identifier}")
        print(f"Export task status: {response['Status']}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Export task started successfully',
                'exportTaskIdentifier': export_task_identifier,
                'snapshotArn': snapshot_arn,
                'status': response['Status']
            })
        }

    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error starting export task',
                'error': str(e)
            })
        }
