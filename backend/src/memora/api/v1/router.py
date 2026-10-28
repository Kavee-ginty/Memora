from fastapi import APIRouter

from memora.api.v1.identity import router as identity_router
from memora.api.v1.ingestion import router as ingestion_router

router = APIRouter(prefix="/v1")
router.include_router(identity_router)
router.include_router(ingestion_router)
