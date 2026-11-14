"""Notification integration domain module.

Owns the push payload contract, provider adapters, delivery enforcement
(quiet hours, frequency caps, category choice) and provider delivery results
(TRD §3.2). The module never selects missions and never writes learning or
memory state. Push is a signaling channel only: payloads carry the closed
allowlist from API §16.2 and clients validate the referenced resource through
the API before navigating (API §16.3).
"""
