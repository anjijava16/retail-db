SRC_DIR=src
BUILD_DIR=build
CREATE_FILES=$(SRC_DIR)/relations.sql $(SRC_DIR)/constraints.sql
CLEAR_FILES=$(SRC_DIR)/clear.sql

# Targets & dependencies

all: $(BUILD_DIR)/create.sql $(BUILD_DIR)/clear.sql

deploy: $(BUILD_DIR)/create.sql $(BUILD_DIR)/clear.sql
	psql < $(BUILD_DIR)/clear.sql
	psql < $(BUILD_DIR)/create.sql

clean:
	rm -rf $(BUILD_DIR)

# Instructions

$(BUILD_DIR)/create.sql: $(CREATE_FILES)
	@mkdir -p $(BUILD_DIR)
	cat > $@ $^

$(BUILD_DIR)/clear.sql: $(CLEAR_FILES)
	@mkdir -p $(BUILD_DIR)
	cat > $@ $^
