import os
from flask import Flask, render_template, request, redirect, url_for
import boto3

app = Flask(__name__)

# Retrieve environment variables (or default values)
BUCKET_NAME = 'my-image-ranking-bucket'
DYNAMODB_TABLE = 'image_rankings'

# Initialize AWS clients
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(DYNAMODB_TABLE)

@app.route('/')
def index():
    # List images from S3
    response = s3.list_objects_v2(Bucket=BUCKET_NAME)
    images = []
    if 'Contents' in response:
        for obj in response['Contents']:
            image_key = obj['Key']
            # Fetch ranking from DynamoDB
            result = table.get_item(Key={'image_id': image_key})
            score = 0
            if 'Item' in result:
                score = result['Item'].get('score', 0)

            # Generate a presigned URL for the image
            image_url = s3.generate_presigned_url(
                'get_object',
                Params={'Bucket': BUCKET_NAME, 'Key': image_key},
                ExpiresIn=3600
            )

            images.append({
                'key': image_key,
                'url': image_url,
                'score': score
            })

    return render_template('index.html', images=images)

@app.route('/vote', methods=['POST'])
def vote():
    image_key = request.form.get('image_key')
    vote_type = request.form.get('vote')  # 'up' or 'down'

    # Get current score from DynamoDB
    result = table.get_item(Key={'image_id': image_key})
    current_score = result['Item'].get('score', 0) if 'Item' in result else 0

    new_score = current_score + 1 if vote_type == 'up' else current_score - 1

    # Update score in DynamoDB
    table.put_item(Item={'image_id': image_key, 'score': new_score})

    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
