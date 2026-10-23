# Memora documentation

This folder contains the canonical product documents, UI source screens, and supporting visual references.

## Structure

```text
docs/
|-- specifications/
|   |-- Memora_PRD.docx
|   |-- Memora_PRD.md
|   |-- Memora_TRD.docx
|   |-- Memora_TRD.md
|   |-- Memora_Backend_Schema_and_Data_Model.docx
|   |-- Memora_Backend_Schema_and_Data_Model.md
|   |-- Memora_App_Flow_and_Screen_State_Specification.docx
|   |-- Memora_App_Flow_and_Screen_State_Specification.md
|   |-- Memora_API_and_Integration_Contract.docx
|   |-- Memora_API_and_Integration_Contract.md
|   |-- Memora_UI_UX_Design_Specification.md
|   |-- Memora_UI_UX_Design_Specification.docx
|   `-- assets/
|       `-- Diagrams referenced by the PRD and TRD Markdown
|-- screens/
|   `-- Student-facing screen PNGs and Mora visual reference
|-- references/
|   `-- ui-ux-audit/
|       `-- Earlier visual audit pages
|-- project-management/
|   |-- Memora_Development_Network_Plan.md
|   |-- Memora_Development_Task_Table.md
|   `-- Memora_Development_Network_Diagram.png
`-- archive/
    `-- Superseded combined plan and preserved legacy folders
```

## Authority order for implementation

1. `specifications/Memora_PRD.md` defines product scope and business rules. The matching DOCX is the human-review copy.
2. `specifications/Memora_TRD.md` defines architecture and technical contracts. The matching DOCX is the human-review copy.
3. `specifications/Memora_UI_UX_Design_Specification.md` defines UI behavior, screen states, accessibility, and approved design changes.
4. `specifications/Memora_Backend_Schema_and_Data_Model.md` defines stored entities, relationships, constraints, ownership, retention and migrations.
5. `specifications/Memora_App_Flow_and_Screen_State_Specification.md` defines routes, guards, screen states, transitions, retries and interruption recovery.
6. `specifications/Memora_API_and_Integration_Contract.md` defines endpoints, payloads, authorization, errors, retries, OpenAPI and integration tests.
7. `screens/*.png` defines the retained visual composition of each supplied screen.
8. `references/ui-ux-audit/*.png` is supporting analysis, not the implementation authority.

Coding agents must read the UI/UX Markdown and open the matching PNG from `screens/` before implementing a screen. When the PNG conflicts with the Markdown, follow the Markdown and document the deviation.
