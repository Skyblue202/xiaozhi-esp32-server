import time
import os
from config.logger import setup_logging
from typing import Optional, Tuple, List
from core.providers.asr.dto.dto import InterfaceType
from core.providers.asr.base import ASRProviderBase

import requests

TAG = __name__
logger = setup_logging()

class ASRProvider(ASRProviderBase):
    def __init__(self, config: dict, delete_audio_file: bool):
        self.interface_type = InterfaceType.NON_STREAM
        self.api_key = config.get("api_key")
        self.api_url = config.get("base_url")
        self.model = config.get("model_name")
        self.language = config.get("language")
        self.prompt = config.get("prompt")
        self.output_dir = config.get("output_dir")
        self.delete_audio_file = delete_audio_file

        os.makedirs(self.output_dir, exist_ok=True)

    def requires_file(self) -> bool:
        return True

    async def speech_to_text(self, opus_data: List[bytes], session_id: str, artifacts=None) -> Tuple[Optional[str], Optional[str]]:
        file_path = None
        try:
            if artifacts is None:
                return "", None
            file_path = artifacts.file_path

            logger.bind(tag=TAG).info(f"file path: {file_path}")
            headers = {
                "Authorization": f"Bearer {self.api_key}",
            }

            # Parámetros de la transcripción
            data = {
                "model": self.model
            }
            # Forzar idioma (ej. "es") para que no adivine
            if self.language:
                data["language"] = self.language
            # Texto de contexto opcional para mejorar la precisión
            if self.prompt:
                data["prompt"] = self.prompt

            with open(file_path, "rb") as audio_file:
                files = {
                    "file": audio_file
                }

                start_time = time.time()
                response = requests.post(
                    self.api_url,
                    files=files,
                    data=data,
                    headers=headers
                )
                logger.bind(tag=TAG).debug(
                    f"Tiempo de reconocimiento: {time.time() - start_time:.3f}s | Resultado: {response.text}"
                )

            if response.status_code == 200:
                text = response.json().get("text", "")
                return text, file_path
            else:
                raise Exception(f"API request failed: {response.status_code} - {response.text}")

        except Exception as e:
            logger.bind(tag=TAG).error(f"Error de reconocimiento de voz: {e}")
            return "", None
