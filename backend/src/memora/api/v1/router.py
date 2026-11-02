from fastapi import APIRouter

from memora.api.v1.identity import router as identity_router
from memora.api.v1.ingestion import router as ingestion_router
from memora.api.v1.memory import router as memory_router
from memora.api.v1.missions import router as missions_router
from memora.api.v1.privacy import router as privacy_router
from memora.api.v1.questions import router as questions_router

router = APIRouter(prefix="/v1")
router.include_router(identity_router)
router.include_router(ingestion_router)
router.include_router(questions_router)
router.include_router(memory_router)
router.include_router(missions_router)
router.include_router(privacy_router)
