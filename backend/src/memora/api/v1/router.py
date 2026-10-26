from fastapi import APIRouter

from memora.api.v1.identity import router as identity_router

router = APIRouter(prefix="/v1")
router.include_router(identity_router)
