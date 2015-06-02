SRC_DIR=src
BUILD_DIR=build
CREATE_FILES=$(SRC_DIR)/schema.sql $(SRC_DIR)/fixtures.sql
CLEAR_FILES=$(SRC_DIR)/clear.sql
SCHEMACRAWLER_DIR=~/Pobrane/schemacrawler-12.06.03-main/_schemacrawler
# Targets & dependencies

all: $(BUILD_DIR)/create.sql $(BUILD_DIR)/clear.sql $(BUILD_DIR)/README.txt $(BUILD_DIR)/diagram.png

deploy: $(BUILD_DIR)/create.sql $(BUILD_DIR)/clear.sql
	@echo "Clearing database..."
	@psql < $(BUILD_DIR)/clear.sql
	@echo "Deploying..."
	@psql < $(BUILD_DIR)/create.sql

clean:
	rm -rf $(BUILD_DIR)

gendiagram: $(BUILD_DIR)/create.sql
	java -cp $$(echo $(SCHEMACRAWLER_DIR)/lib/*.jar | tr ' ' ':') schemacrawler.Main -server=postgresql -user=${USER} -database=${USER} -infolevel=standard -command=graph -outputformat=png -outputfile=$(SRC_DIR)/diagram.png

# Instructions

$(BUILD_DIR)/create.sql: $(CREATE_FILES)
	@mkdir -p $(BUILD_DIR)
	cat > $@ $^

$(BUILD_DIR)/clear.sql: $(CLEAR_FILES)
	@mkdir -p $(BUILD_DIR)
	cat > $@ $^

$(BUILD_DIR)/README.txt: $(SRC_DIR)/README.md
	cp $^ $@

$(BUILD_DIR)/diagram.png: $(SRC_DIR)/diagram.png
	cp $^ $@
