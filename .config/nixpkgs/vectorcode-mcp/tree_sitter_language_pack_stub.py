# Stub module for tree_sitter_language_pack
import enum
from typing import Any

class SupportedLanguage(enum.Enum):
    PYTHON = "python"
    JAVASCRIPT = "javascript" 
    TYPESCRIPT = "typescript"
    GO = "go"
    RUST = "rust"
    C = "c"
    CPP = "cpp"

def get_parser(language: SupportedLanguage) -> Any:
    # Return a dummy parser
    class DummyParser:
        def parse(self, source_code: bytes) -> Any:
            class DummyTree:
                def root_node(self) -> Any:
                    class DummyNode:
                        def __init__(self):
                            self.children = []
                            self.type = "module"
                            self.start_byte = 0
                            self.end_byte = len(source_code)
                    return DummyNode()
            return DummyTree()
    return DummyParser()
EOF < /dev/null
