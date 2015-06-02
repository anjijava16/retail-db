SRC_DIR=src
BUILD_DIR=build
CREATE_FILES=$(SRC_DIR)/schema.sql
CLEAR_FILES=$(SRC_DIR)/clear.sql

# Targets & dependencies

all: $(BUILD_DIR)/create.sql $(BUILD_DIR)/clear.sql $(BUILD_DIR)/README.txt $(BUILD_DIR)/diagram.png

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

$(BUILD_DIR)/README.txt: $(SRC_DIR)/README.txt
	cp $^ $@

$(BUILD_DIR)/diagram.png: $(SRC_DIR)/diagram.png
	cp $^ $@