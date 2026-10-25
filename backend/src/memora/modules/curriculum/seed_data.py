"""Structured, versioned seed data for NIE G.C.E. A/L Physics (2017) curriculum."""

from typing import Any

PROVENANCE_NIE_2017 = "NIE Sri Lanka G.C.E. (A/L) Physics Syllabus (2017)"

# ---------------------------------------------------------------------------
# Learning Objectives
# ---------------------------------------------------------------------------
LEARNING_OBJECTIVES: list[dict[str, Any]] = [
    # Unit 1: Measurement
    {
        "id": "30000000-0000-0000-0000-000000000001",
        "objective_code": "LO-PHYS-01-MEAS",
        "parent_objective_id": None,
        "title": "Measurement",
        "description": "Units, dimensions, and measurement techniques in physics.",
        "sequence_no": 1,
        "status": "approved",
    },
    {
        "id": "30000000-0000-0000-0000-000000000002",
        "objective_code": "LO-PHYS-01-01-UNITS",
        "parent_objective_id": "30000000-0000-0000-0000-000000000001",
        "title": "Physical Quantities and SI Units",
        "description": "Distinguish between base and derived physical quantities and units.",
        "sequence_no": 1,
        "status": "approved",
    },
    {
        "id": "30000000-0000-0000-0000-000000000003",
        "objective_code": "LO-PHYS-01-02-DIMS",
        "parent_objective_id": "30000000-0000-0000-0000-000000000001",
        "title": "Dimensions and Dimensional Analysis",
        "description": "Determine dimensions of physical quantities and equation homogeneity.",
        "sequence_no": 2,
        "status": "approved",
    },
    # Unit 2: Mechanics
    {
        "id": "30000000-0000-0000-0000-000000000004",
        "objective_code": "LO-PHYS-02-MECH",
        "parent_objective_id": None,
        "title": "Mechanics",
        "description": "Kinematics, dynamics, energy, and rotational motion.",
        "sequence_no": 2,
        "status": "approved",
    },
    {
        "id": "30000000-0000-0000-0000-000000000005",
        "objective_code": "LO-PHYS-02-01-KINEMATICS",
        "parent_objective_id": "30000000-0000-0000-0000-000000000004",
        "title": "Kinematics in One Dimension",
        "description": "Describe rectilinear motion using displacement, velocity, acceleration.",
        "sequence_no": 1,
        "status": "approved",
    },
    {
        "id": "30000000-0000-0000-0000-000000000006",
        "objective_code": "LO-PHYS-02-02-NEWTON-LAWS",
        "parent_objective_id": "30000000-0000-0000-0000-000000000004",
        "title": "Newton's Laws of Motion and Momentum",
        "description": "Apply Newton's laws of motion and conservation of linear momentum.",
        "sequence_no": 2,
        "status": "approved",
    },
    {
        "id": "30000000-0000-0000-0000-000000000007",
        "objective_code": "LO-PHYS-02-03-WORK-ENERGY",
        "parent_objective_id": "30000000-0000-0000-0000-000000000004",
        "title": "Work, Energy, and Power",
        "description": "Analyze mechanical work, kinetic and potential energy, and power.",
        "sequence_no": 3,
        "status": "approved",
    },
    # Unit 3: Oscillations and Waves
    {
        "id": "30000000-0000-0000-0000-000000000008",
        "objective_code": "LO-PHYS-03-WAVES",
        "parent_objective_id": None,
        "title": "Oscillations and Waves",
        "description": "Simple harmonic motion and wave properties.",
        "sequence_no": 3,
        "status": "approved",
    },
    {
        "id": "30000000-0000-0000-0000-000000000009",
        "objective_code": "LO-PHYS-03-01-SHM",
        "parent_objective_id": "30000000-0000-0000-0000-000000000008",
        "title": "Simple Harmonic Motion",
        "description": "Characteristics and equations of simple harmonic motion.",
        "sequence_no": 1,
        "status": "approved",
    },
]

# ---------------------------------------------------------------------------
# Concepts and Concept Versions
# ---------------------------------------------------------------------------
CONCEPTS_DATA: list[dict[str, Any]] = [
    {
        "concept_id": "40000000-0000-0000-0000-000000000001",
        "stable_code": "PHYS-MEA-SI-UNITS",
        "version_id": "50000000-0000-0000-0000-000000000001",
        "kind": "concept",
        "title": "International System of Units (SI)",
        "definition": (
            "A coherent system of units based on seven fundamental base quantities: "
            "length, mass, time, electric current, thermodynamic temperature, amount of substance, "
            "and luminous intensity."
        ),
        "symbol_context": {"base_units": ["m", "kg", "s", "A", "K", "mol", "cd"]},
        "unit_context": {"system": "SI"},
        "objective_code": "LO-PHYS-01-01-UNITS",
        "aliases": [
            {"text": "SI Units", "type": "term", "is_preferred": True},
            {"text": "International System of Units", "type": "term", "is_preferred": False},
            {"text": "SI", "type": "abbreviation", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000001",
                "group_id": "71000000-0000-0000-0000-000000000001",
                "claim_type": "definition",
                "statement": (
                    "SI is the globally adopted metric system consisting of seven fundamental "
                    "base units."
                ),
            }
        ],
    },
    {
        "concept_id": "40000000-0000-0000-0000-000000000002",
        "stable_code": "PHYS-MEA-DIMENSIONS",
        "version_id": "50000000-0000-0000-0000-000000000002",
        "kind": "concept",
        "title": "Dimensions of Physical Quantities",
        "definition": (
            "The powers to which fundamental base quantities must be raised to represent "
            "a physical quantity, denoted by [M], [L], [T], [I], [θ], [N], and [J]."
        ),
        "symbol_context": {"notation": "[Q] = M^a L^b T^c"},
        "unit_context": {"base_dimensions": ["M", "L", "T", "I", "θ", "N", "J"]},
        "objective_code": "LO-PHYS-01-02-DIMS",
        "aliases": [
            {"text": "Dimensional Analysis", "type": "term", "is_preferred": True},
            {"text": "Dimensions", "type": "term", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000002",
                "group_id": "71000000-0000-0000-0000-000000000002",
                "claim_type": "condition",
                "statement": (
                    "Only terms having the same dimensions can be added, subtracted, or equated "
                    "(Principle of Homogeneity)."
                ),
            }
        ],
    },
    {
        "concept_id": "40000000-0000-0000-0000-000000000003",
        "stable_code": "PHYS-MEC-DISPLACEMENT",
        "version_id": "50000000-0000-0000-0000-000000000003",
        "kind": "variable",
        "title": "Displacement",
        "definition": (
            "The vector change in position of an object from an initial point to a final "
            "point in a specified direction."
        ),
        "symbol_context": {"symbol": "s", "vector": True},
        "unit_context": {"unit": "metre", "symbol": "m", "dimensions": "L"},
        "objective_code": "LO-PHYS-02-01-KINEMATICS",
        "aliases": [
            {"text": "Displacement", "type": "term", "is_preferred": True},
            {"text": "s", "type": "symbol", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000003",
                "group_id": "71000000-0000-0000-0000-000000000003",
                "claim_type": "definition",
                "statement": (
                    "Displacement is the straight-line directed distance between start and end."
                ),
            }
        ],
    },
    {
        "concept_id": "40000000-0000-0000-0000-000000000004",
        "stable_code": "PHYS-MEC-VELOCITY",
        "version_id": "50000000-0000-0000-0000-000000000004",
        "kind": "variable",
        "title": "Velocity",
        "definition": "The rate of change of displacement of an object with respect to time.",
        "symbol_context": {"symbol": "v", "vector": True, "formula": "v = ds/dt"},
        "unit_context": {"unit": "metre per second", "symbol": "m s^-1", "dimensions": "L T^-1"},
        "objective_code": "LO-PHYS-02-01-KINEMATICS",
        "aliases": [
            {"text": "Velocity", "type": "term", "is_preferred": True},
            {"text": "v", "type": "symbol", "is_preferred": False},
            {"text": "velocity vector", "type": "term", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000004",
                "group_id": "71000000-0000-0000-0000-000000000004",
                "claim_type": "formula",
                "statement": "Velocity is the first time derivative of displacement: v = ds/dt.",
            }
        ],
    },
    {
        "concept_id": "40000000-0000-0000-0000-000000000005",
        "stable_code": "PHYS-MEC-ACCELERATION",
        "version_id": "50000000-0000-0000-0000-000000000005",
        "kind": "variable",
        "title": "Acceleration",
        "definition": "The rate of change of velocity of an object with respect to time.",
        "symbol_context": {"symbol": "a", "vector": True, "formula": "a = dv/dt"},
        "unit_context": {
            "unit": "metre per second squared",
            "symbol": "m s^-2",
            "dimensions": "L T^-2",
        },
        "objective_code": "LO-PHYS-02-01-KINEMATICS",
        "aliases": [
            {"text": "Acceleration", "type": "term", "is_preferred": True},
            {"text": "a", "type": "symbol", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000005",
                "group_id": "71000000-0000-0000-0000-000000000005",
                "claim_type": "formula",
                "statement": "Acceleration is the time rate of change of velocity: a = dv/dt.",
            }
        ],
    },
    {
        "concept_id": "40000000-0000-0000-0000-000000000006",
        "stable_code": "PHYS-MEC-MOMENTUM",
        "version_id": "50000000-0000-0000-0000-000000000006",
        "kind": "variable",
        "title": "Linear Momentum",
        "definition": (
            "The product of mass and velocity of a body, pointing in the direction of velocity."
        ),
        "symbol_context": {"symbol": "p", "vector": True, "formula": "p = m * v"},
        "unit_context": {
            "unit": "kilogram metre per second",
            "symbol": "kg m s^-1",
            "dimensions": "M L T^-1",
        },
        "objective_code": "LO-PHYS-02-02-NEWTON-LAWS",
        "aliases": [
            {"text": "Linear Momentum", "type": "term", "is_preferred": True},
            {"text": "Momentum", "type": "term", "is_preferred": False},
            {"text": "p", "type": "symbol", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000006",
                "group_id": "71000000-0000-0000-0000-000000000006",
                "claim_type": "definition",
                "statement": (
                    "Linear momentum p = mv is a vector quantity having the direction of velocity."
                ),
            }
        ],
    },
    {
        "concept_id": "40000000-0000-0000-0000-000000000007",
        "stable_code": "PHYS-MEC-NEWTON1",
        "version_id": "50000000-0000-0000-0000-000000000007",
        "kind": "law",
        "title": "Newton's First Law of Motion",
        "definition": (
            "A body continues in its state of rest or uniform motion in a straight line "
            "unless acted upon by an external unbalanced resultant force."
        ),
        "symbol_context": {"condition": "ΣF = 0 => a = 0, v = constant"},
        "unit_context": None,
        "objective_code": "LO-PHYS-02-02-NEWTON-LAWS",
        "aliases": [
            {"text": "Newton's First Law", "type": "term", "is_preferred": True},
            {"text": "Law of Inertia", "type": "term", "is_preferred": False},
            {"text": "Newton 1", "type": "abbreviation", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000007",
                "group_id": "71000000-0000-0000-0000-000000000007",
                "claim_type": "definition",
                "statement": (
                    "In the absence of a resultant external force, an object maintains "
                    "constant velocity."
                ),
            },
            {
                "claim_id": "70000000-0000-0000-0000-000000000008",
                "group_id": "71000000-0000-0000-0000-000000000008",
                "claim_type": "misconception",
                "statement": (
                    "A continuous force is required to keep an object moving with uniform velocity."
                ),
            },
        ],
    },
    {
        "concept_id": "40000000-0000-0000-0000-000000000008",
        "stable_code": "PHYS-MEC-NEWTON2",
        "version_id": "50000000-0000-0000-0000-000000000008",
        "kind": "law",
        "title": "Newton's Second Law of Motion",
        "definition": (
            "The rate of change of linear momentum of a body is directly proportional to "
            "the applied resultant force and occurs in the direction of the force."
        ),
        "symbol_context": {"formula": "F = dp/dt = m * a (for constant mass)", "vector": True},
        "unit_context": {
            "unit": "newton",
            "symbol": "N",
            "base_units": "kg m s^-2",
            "dimensions": "M L T^-2",
        },
        "objective_code": "LO-PHYS-02-02-NEWTON-LAWS",
        "aliases": [
            {"text": "Newton's Second Law", "type": "term", "is_preferred": True},
            {"text": "F = ma", "type": "symbol", "is_preferred": False},
            {"text": "Newton 2", "type": "abbreviation", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000009",
                "group_id": "71000000-0000-0000-0000-000000000009",
                "claim_type": "formula",
                "statement": "Resultant Force F = dp/dt. When mass m is constant, F = ma.",
            }
        ],
    },
    {
        "concept_id": "40000000-0000-0000-0000-000000000009",
        "stable_code": "PHYS-MEC-NEWTON3",
        "version_id": "50000000-0000-0000-0000-000000000009",
        "kind": "law",
        "title": "Newton's Third Law of Motion",
        "definition": (
            "When two bodies interact, the force exerted by the first body on the second is "
            "equal in magnitude and opposite in direction to the force exerted by the second "
            "body on the first."
        ),
        "symbol_context": {"formula": "F_AB = -F_BA"},
        "unit_context": {"unit": "newton", "symbol": "N"},
        "objective_code": "LO-PHYS-02-02-NEWTON-LAWS",
        "aliases": [
            {"text": "Newton's Third Law", "type": "term", "is_preferred": True},
            {"text": "Action and Reaction", "type": "term", "is_preferred": False},
            {"text": "Newton 3", "type": "abbreviation", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000010",
                "group_id": "71000000-0000-0000-0000-000000000010",
                "claim_type": "condition",
                "statement": (
                    "Action and reaction forces act on different bodies and are of the exact "
                    "same physical nature."
                ),
            }
        ],
    },
    {
        "concept_id": "40000000-0000-0000-0000-000000000010",
        "stable_code": "PHYS-MEC-WORK",
        "version_id": "50000000-0000-0000-0000-000000000010",
        "kind": "concept",
        "title": "Work Done by a Force",
        "definition": (
            "The product of the magnitude of displacement and the component of force "
            "in the direction of displacement."
        ),
        "symbol_context": {"formula": "W = F * s * cos(theta)", "scalar": True},
        "unit_context": {
            "unit": "joule",
            "symbol": "J",
            "base_units": "kg m^2 s^-2",
            "dimensions": "M L^2 T^-2",
        },
        "objective_code": "LO-PHYS-02-03-WORK-ENERGY",
        "aliases": [
            {"text": "Work", "type": "term", "is_preferred": True},
            {"text": "Mechanical Work", "type": "term", "is_preferred": False},
            {"text": "W", "type": "symbol", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000011",
                "group_id": "71000000-0000-0000-0000-000000000011",
                "claim_type": "formula",
                "statement": (
                    "Work W = F · s = F s cos(θ). Work is zero if displacement is "
                    "perpendicular to force."
                ),
            }
        ],
    },
    {
        "concept_id": "40000000-0000-0000-0000-000000000011",
        "stable_code": "PHYS-MEC-KINETIC-ENERGY",
        "version_id": "50000000-0000-0000-0000-000000000011",
        "kind": "concept",
        "title": "Kinetic Energy",
        "definition": (
            "The energy possessed by a body due to its motion, defined as half the product of "
            "mass and speed squared."
        ),
        "symbol_context": {"symbol": "E_k", "formula": "E_k = 0.5 * m * v^2", "scalar": True},
        "unit_context": {"unit": "joule", "symbol": "J", "dimensions": "M L^2 T^-2"},
        "objective_code": "LO-PHYS-02-03-WORK-ENERGY",
        "aliases": [
            {"text": "Kinetic Energy", "type": "term", "is_preferred": True},
            {"text": "Ek", "type": "symbol", "is_preferred": False},
            {"text": "KE", "type": "abbreviation", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000012",
                "group_id": "71000000-0000-0000-0000-000000000012",
                "claim_type": "formula",
                "statement": "E_k = (1/2) * m * v^2 = p^2 / (2m).",
            }
        ],
    },
    {
        "concept_id": "40000000-0000-0000-0000-000000000012",
        "stable_code": "PHYS-MEC-GRAV-POT-ENERGY",
        "version_id": "50000000-0000-0000-0000-000000000012",
        "kind": "concept",
        "title": "Gravitational Potential Energy",
        "definition": (
            "The energy possessed by a body due to its position in a gravitational field "
            "relative to a reference level."
        ),
        "symbol_context": {"symbol": "E_p", "formula": "E_p = m * g * h", "scalar": True},
        "unit_context": {"unit": "joule", "symbol": "J", "dimensions": "M L^2 T^-2"},
        "objective_code": "LO-PHYS-02-03-WORK-ENERGY",
        "aliases": [
            {"text": "Gravitational Potential Energy", "type": "term", "is_preferred": True},
            {"text": "Potential Energy", "type": "term", "is_preferred": False},
            {"text": "GPE", "type": "abbreviation", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000013",
                "group_id": "71000000-0000-0000-0000-000000000013",
                "claim_type": "formula",
                "statement": "Near Earth's surface, E_p = mgh relative to reference height h = 0.",
            }
        ],
    },
    {
        "concept_id": "40000000-0000-0000-0000-000000000013",
        "stable_code": "PHYS-MEC-CONSERV-ENERGY",
        "version_id": "50000000-0000-0000-0000-000000000013",
        "kind": "principle",
        "title": "Principle of Conservation of Mechanical Energy",
        "definition": (
            "In an isolated system where only conservative forces do work, the total mechanical "
            "energy (sum of kinetic and potential energies) remains constant over time."
        ),
        "symbol_context": {"formula": "E_total = E_k + E_p = constant"},
        "unit_context": {"unit": "joule", "symbol": "J"},
        "objective_code": "LO-PHYS-02-03-WORK-ENERGY",
        "aliases": [
            {"text": "Conservation of Mechanical Energy", "type": "term", "is_preferred": True},
            {"text": "Conservation of Energy", "type": "term", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000014",
                "group_id": "71000000-0000-0000-0000-000000000014",
                "claim_type": "condition",
                "statement": (
                    "Mechanical energy is conserved only when non-conservative forces do zero work."
                ),
            }
        ],
    },
    {
        "concept_id": "40000000-0000-0000-0000-000000000014",
        "stable_code": "PHYS-WAV-SHM",
        "version_id": "50000000-0000-0000-0000-000000000014",
        "kind": "concept",
        "title": "Simple Harmonic Motion",
        "definition": (
            "Periodic motion where acceleration is directly proportional to displacement "
            "from equilibrium and is always directed towards the equilibrium position."
        ),
        "symbol_context": {"formula": "a = -omega^2 * x"},
        "unit_context": None,
        "objective_code": "LO-PHYS-03-01-SHM",
        "aliases": [
            {"text": "Simple Harmonic Motion", "type": "term", "is_preferred": True},
            {"text": "SHM", "type": "abbreviation", "is_preferred": False},
        ],
        "claims": [
            {
                "claim_id": "70000000-0000-0000-0000-000000000015",
                "group_id": "71000000-0000-0000-0000-000000000015",
                "claim_type": "definition",
                "statement": (
                    "Defining condition of SHM: acceleration is proportional to displacement "
                    "from center and directed opposite to displacement."
                ),
            }
        ],
    },
]

# ---------------------------------------------------------------------------
# Concept Edges (Prerequisites & Semantic Relationships)
# Strict Directed Acyclic Graph (DAG) for prerequisite_of
# ---------------------------------------------------------------------------
CONCEPT_EDGES: list[dict[str, Any]] = [
    # Units -> Dimensions
    {
        "id": "80000000-0000-0000-0000-000000000001",
        "from_version_id": "50000000-0000-0000-0000-000000000001",  # SI Units
        "to_version_id": "50000000-0000-0000-0000-000000000002",  # Dimensions
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Units -> Displacement
    {
        "id": "80000000-0000-0000-0000-000000000002",
        "from_version_id": "50000000-0000-0000-0000-000000000001",  # SI Units
        "to_version_id": "50000000-0000-0000-0000-000000000003",  # Displacement
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Displacement -> Velocity
    {
        "id": "80000000-0000-0000-0000-000000000003",
        "from_version_id": "50000000-0000-0000-0000-000000000003",  # Displacement
        "to_version_id": "50000000-0000-0000-0000-000000000004",  # Velocity
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Velocity -> Acceleration
    {
        "id": "80000000-0000-0000-0000-000000000004",
        "from_version_id": "50000000-0000-0000-0000-000000000004",  # Velocity
        "to_version_id": "50000000-0000-0000-0000-000000000005",  # Acceleration
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Velocity -> Momentum
    {
        "id": "80000000-0000-0000-0000-000000000005",
        "from_version_id": "50000000-0000-0000-0000-000000000004",  # Velocity
        "to_version_id": "50000000-0000-0000-0000-000000000006",  # Momentum
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Newton 1 -> Newton 2
    {
        "id": "80000000-0000-0000-0000-000000000006",
        "from_version_id": "50000000-0000-0000-0000-000000000007",  # Newton 1
        "to_version_id": "50000000-0000-0000-0000-000000000008",  # Newton 2
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Acceleration -> Newton 2
    {
        "id": "80000000-0000-0000-0000-000000000007",
        "from_version_id": "50000000-0000-0000-0000-000000000005",  # Acceleration
        "to_version_id": "50000000-0000-0000-0000-000000000008",  # Newton 2
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Momentum -> Newton 2
    {
        "id": "80000000-0000-0000-0000-000000000008",
        "from_version_id": "50000000-0000-0000-0000-000000000006",  # Momentum
        "to_version_id": "50000000-0000-0000-0000-000000000008",  # Newton 2
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Newton 2 -> Newton 3
    {
        "id": "80000000-0000-0000-0000-000000000009",
        "from_version_id": "50000000-0000-0000-0000-000000000008",  # Newton 2
        "to_version_id": "50000000-0000-0000-0000-000000000009",  # Newton 3
        "edge_type": "related_to",
        "confidence": 1.0,
    },
    # Displacement -> Work
    {
        "id": "80000000-0000-0000-0000-000000000010",
        "from_version_id": "50000000-0000-0000-0000-000000000003",  # Displacement
        "to_version_id": "50000000-0000-0000-0000-000000000010",  # Work
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Newton 2 -> Work
    {
        "id": "80000000-0000-0000-0000-000000000011",
        "from_version_id": "50000000-0000-0000-0000-000000000008",  # Newton 2
        "to_version_id": "50000000-0000-0000-0000-000000000010",  # Work
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Work -> Kinetic Energy
    {
        "id": "80000000-0000-0000-0000-000000000012",
        "from_version_id": "50000000-0000-0000-0000-000000000010",  # Work
        "to_version_id": "50000000-0000-0000-0000-000000000011",  # Kinetic Energy
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Work -> Gravitational Potential Energy
    {
        "id": "80000000-0000-0000-0000-000000000013",
        "from_version_id": "50000000-0000-0000-0000-000000000010",  # Work
        "to_version_id": "50000000-0000-0000-0000-000000000012",  # GPE
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Kinetic Energy -> Conservation of Mechanical Energy
    {
        "id": "80000000-0000-0000-0000-000000000014",
        "from_version_id": "50000000-0000-0000-0000-000000000011",  # Kinetic Energy
        "to_version_id": "50000000-0000-0000-0000-000000000013",  # Conservation Energy
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Gravitational Potential Energy -> Conservation of Mechanical Energy
    {
        "id": "80000000-0000-0000-0000-000000000015",
        "from_version_id": "50000000-0000-0000-0000-000000000012",  # GPE
        "to_version_id": "50000000-0000-0000-0000-000000000013",  # Conservation Energy
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
    # Acceleration -> SHM
    {
        "id": "80000000-0000-0000-0000-000000000016",
        "from_version_id": "50000000-0000-0000-0000-000000000005",  # Acceleration
        "to_version_id": "50000000-0000-0000-0000-000000000014",  # SHM
        "edge_type": "prerequisite_of",
        "confidence": 1.0,
    },
]

# ---------------------------------------------------------------------------
# Initial Reward Definitions (Schema §18.2)
# ---------------------------------------------------------------------------
REWARD_DEFINITIONS: list[dict[str, Any]] = [
    {
        "id": "90000000-0000-0000-0000-000000000001",
        "reward_code": "REWARD-CORAL-SPROUT",
        "reward_type": "decoration",
        "title": "Coral Sprout",
        "asset_key": "assets/rewards/decorations/coral_sprout.png",
        "xp_threshold": 100,
        "status": "approved",
    },
    {
        "id": "90000000-0000-0000-0000-000000000002",
        "reward_code": "REWARD-ANEMONE-CLUSTER",
        "reward_type": "decoration",
        "title": "Anemone Cluster",
        "asset_key": "assets/rewards/decorations/anemone_cluster.png",
        "xp_threshold": 300,
        "status": "approved",
    },
    {
        "id": "90000000-0000-0000-0000-000000000003",
        "reward_code": "REWARD-MORA-SNORKEL",
        "reward_type": "mora_cosmetic",
        "title": "Mora Snorkel Gear",
        "asset_key": "assets/rewards/cosmetics/mora_snorkel.png",
        "xp_threshold": 500,
        "status": "approved",
    },
    {
        "id": "90000000-0000-0000-0000-000000000004",
        "reward_code": "REWARD-GOLDEN-SHELL",
        "reward_type": "decoration",
        "title": "Golden Cowrie Shell",
        "asset_key": "assets/rewards/decorations/golden_shell.png",
        "xp_threshold": 1000,
        "status": "approved",
    },
]
