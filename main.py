from fastapi import FastAPI, File, UploadFile
from loguru import logger
from PIL import Image
from io import BytesIO

from transformers import VisionEncoderDecoderModel, ViTFeatureExtractor, AutoTokenizer

app = FastAPI()

model = VisionEncoderDecoderModel.from_pretrained("nlpconnect/vit-gpt2-image-captioning")
feature_extractor = ViTFeatureExtractor.from_pretrained("nlpconnect/vit-gpt2-image-captioning")
tokenizer = AutoTokenizer.from_pretrained("nlpconnect/vit-gpt2-image-captioning")

max_length = 16
num_beams = 4
gen_kwargs = {"max_length": max_length, "num_beams": num_beams}

@app.post("/caption")
async def detect(file: UploadFile = File(...)):
    request_object_content = await file.read()
    pil_image = Image.open(BytesIO(request_object_content))

    logger.info("Read image successfully!")

    pixel_values = feature_extractor(images=[pil_image], return_tensors="pt").pixel_values

    output_ids = model.generate(pixel_values, **gen_kwargs)

    preds = tokenizer.batch_decode(output_ids, skip_special_tokens=True)
    logger.info("Make predictions successfully!")

    preds = [pred.strip() for pred in preds]

    logger.info("Parse results from predictions successfully!")
    return {"caption": preds[0]}
