import os, json, uuid, boto3, botocore
from datetime import datetime

s3 = boto3.client('s3')
polly = boto3.client('polly')

AUDIO_BUCKET = os.environ.get('AUDIO_BUCKET')
AUDIO_PREFIX = os.environ.get('AUDIO_PREFIX', 'audio/')
UPLOADS_BUCKET = os.environ.get('UPLOADS_BUCKET')
UPLOADS_PREFIX = os.environ.get('UPLOADS_PREFIX', 'uploads/')
AUDIO_FORMAT = os.environ.get('AUDIO_FORMAT', 'mp3')
DEFAULT_VOICE = os.environ.get('DEFAULT_VOICE', 'Joanna')

ALLOWED_VOICES = None

def _load_allowed_voices():
    global ALLOWED_VOICES
    if ALLOWED_VOICES is not None:
        return
    voices = []
    paginator = polly.get_paginator('describe_voices')
    for page in paginator.paginate():
        for v in page.get('Voices', []):
            if 'English' in ''.join(v.get('LanguageName','')):
                voices.append(v['Id'])
    base = ["Joanna","Matthew","Amy","Brian","Emma","Ivy","Justin","Kendra","Salli"]
    ALLOWED_VOICES = sorted(set(voices + base))

def lambda_handler(event, context):
    try:
        route = (event.get("requestContext", {}).get("http", {}).get("path") or "").lower()
        method = (event.get("requestContext", {}).get("http", {}).get("method") or "").upper()

        if route.endswith("/voices") and method == "GET":
            _load_allowed_voices()
            return _resp(200, {"voices": ALLOWED_VOICES})

        if route.endswith("/synthesize") and method == "POST":
            body = event.get('body') or "{}"
            if isinstance(body, str):
                body = json.loads(body)
            text = (body.get('text') or "").strip()
            voice = (body.get('voice') or DEFAULT_VOICE).strip()

            if not text:
                return _resp(400, {"error": "Missing 'text'."})

            _load_allowed_voices()
            if voice not in ALLOWED_VOICES:
                return _resp(400, {"error": f"Unsupported voice '{voice}'."})

            synth = polly.synthesize_speech(Text=text, OutputFormat=AUDIO_FORMAT, VoiceId=voice)
            audio_stream = synth.get("AudioStream")
            if not audio_stream:
                return _resp(502, {"error": "No audio stream from Polly."})

            audio_bytes = audio_stream.read()
            key = f"{AUDIO_PREFIX}{datetime.utcnow():%Y/%m/%d}/{uuid.uuid4()}.{AUDIO_FORMAT}"

            s3.put_object(Bucket=AUDIO_BUCKET, Key=key, Body=audio_bytes, ContentType="audio/mpeg")
            url = s3.generate_presigned_url('get_object', Params={'Bucket': AUDIO_BUCKET, 'Key': key}, ExpiresIn=3600)

            return _resp(200, {"url": url, "key": key, "voice": voice})

        return _resp(404, {"error": "Not found"})
    except botocore.exceptions.ClientError as e:
        return _resp(500, {"error": "AWS error", "detail": str(e)})
    except Exception as e:
        return _resp(500, {"error": "Server error", "detail": str(e)})

def _resp(status, body):
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,GET,POST"
        },
        "body": json.dumps(body)
    }
