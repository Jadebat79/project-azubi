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
PRESIGN_TTL = int(os.environ.get('PRESIGN_TTL', '3600'))  # seconds

VOICES = None  # cached on first call

def _ensure_voices():
    global VOICES
    if VOICES is not None:
        return
    items = []
    paginator = polly.get_paginator('describe_voices')
    for page in paginator.paginate():
        for v in page.get('Voices', []):
            items.append({
                "id": v["Id"],                               # e.g. "Joanna"
                "languageCode": v.get("LanguageCode"),        # e.g. "en-US"
                "languageName": v.get("LanguageName"),        # e.g. "US English"
                "gender": v.get("Gender"),
                "supportedEngines": v.get("SupportedEngines", ["standard"])
            })
    # keep deterministic ordering
    items.sort(key=lambda x: (x["languageCode"] or "", x["id"]))
    VOICES = items

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

def lambda_handler(event, context):
    try:
        http = event.get("requestContext", {}).get("http", {})
        route = (http.get("path") or "").lower()
        method = (http.get("method") or "").upper()

        if route.endswith("/voices") and method == "GET":
            _ensure_voices()
            qs = event.get("queryStringParameters") or {}
            lang = (qs.get("lang") or "").strip()  # e.g. "fr-FR" or "fr"
            items = VOICES
            if lang:
                items = [v for v in VOICES if v["languageCode"] and
                         (v["languageCode"] == lang or v["languageCode"].startswith(lang + "-") or v["languageCode"].startswith(lang))]
            return _resp(200, {"voices": items})

        if route.endswith("/synthesize") and method == "POST":
            body = event.get("body") or "{}"
            if isinstance(body, str):
                body = json.loads(body)

            text = (body.get("text") or "").strip()
            voice = (body.get("voice") or DEFAULT_VOICE).strip()
            engine = (body.get("engine") or "").strip()  # "", "neural"
            force_ssml = bool(body.get("ssml"))

            if not text:
                return _resp(400, {"error": "Missing 'text'."})
            _ensure_voices()
            if not any(v["id"] == voice for v in VOICES):
                return _resp(400, {"error": f"Unsupported voice '{voice}'."})

            # Determine TextType + Engine
            text_is_ssml = force_ssml or text.lstrip().lower().startswith("<speak")
            synth_args = {"Text": text, "OutputFormat": AUDIO_FORMAT, "VoiceId": voice}
            if text_is_ssml:
                synth_args["TextType"] = "ssml"
            if engine:
                synth_args["Engine"] = engine

            synth = polly.synthesize_speech(**synth_args)
            stream = synth.get("AudioStream")
            if not stream:
                return _resp(502, {"error": "No audio stream from Polly."})

            audio_bytes = stream.read()
            key = f"{AUDIO_PREFIX}{datetime.utcnow():%Y/%m/%d}/{uuid.uuid4()}.{AUDIO_FORMAT}"

            s3.put_object(Bucket=AUDIO_BUCKET, Key=key, Body=audio_bytes, ContentType="audio/mpeg")
            url = s3.generate_presigned_url('get_object',
                                            Params={'Bucket': AUDIO_BUCKET, 'Key': key},
                                            ExpiresIn=PRESIGN_TTL)
            return _resp(200, {"url": url, "key": key, "voice": voice})

        return _resp(404, {"error": "Not found"})
    except botocore.exceptions.ClientError as e:
        return _resp(500, {"error": "AWS error", "detail": str(e)})
    except Exception as e:
        return _resp(500, {"error": "Server error", "detail": str(e)})
