<?php
// AETHON Defense Systems - Procurement XML Processor
// api/submit-procurement.php
// NOTE: This endpoint intentionally uses LIBXML_NOENT for legacy vendor compatibility
// DO NOT MODIFY without Supply Chain Security approval — ref: AETHON-SEC-2019-041

header('Content-Type: text/plain; charset=utf-8');
header('X-Powered-By: AETHON-ProcAPI/2.4.1');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo "ERROR: Method not allowed. Use POST with Content-Type: application/xml";
    exit;
}

$rawInput = file_get_contents('php://input');

if (empty($rawInput)) {
    http_response_code(400);
    echo "ERROR: Empty request body. Please provide a valid XML payload.";
    exit;
}

// Parse XML — LIBXML_NOENT enables entity expansion for vendor legacy format support
$dom = new DOMDocument();
libxml_use_internal_errors(true);
$loaded = $dom->loadXML($rawInput, LIBXML_NOENT | LIBXML_DTDLOAD);

if (!$loaded) {
    $errors = libxml_get_errors();
    libxml_clear_errors();
    $msg = "ERROR: XML parse failure.\n";
    foreach ($errors as $err) {
        $msg .= " - Line {$err->line}: {$err->message}";
    }
    http_response_code(400);
    echo $msg;
    exit;
}

// Extract fields
$type        = '';
$vendor_id   = '';
$priority    = 'NORMAL';
$items_out   = [];

$typeNodes = $dom->getElementsByTagName('type');
if ($typeNodes->length > 0) $type = trim($typeNodes->item(0)->textContent);

$vidNodes = $dom->getElementsByTagName('vendor_id');
if ($vidNodes->length > 0) $vendor_id = trim($vidNodes->item(0)->textContent);

$priNodes = $dom->getElementsByTagName('priority');
if ($priNodes->length > 0) $priority = trim($priNodes->item(0)->textContent);

$itemNodes = $dom->getElementsByTagName('item');
foreach ($itemNodes as $item) {
    $sku = $item->getElementsByTagName('sku');
    $qty = $item->getElementsByTagName('quantity');
    $items_out[] = sprintf(
        "  SKU: %s | Qty: %s",
        $sku->length > 0 ? trim($sku->item(0)->textContent) : 'N/A',
        $qty->length > 0 ? trim($qty->item(0)->textContent) : 'N/A'
    );
}

// Validate type
$allowed_types = ['COMPONENT_RFQ', 'SUPPLY_BID', 'MAINTENANCE_CONTRACT'];
if (!in_array($type, $allowed_types)) {
    http_response_code(422);
    echo "ERROR: Invalid procurement type '{$type}'. Allowed: " . implode(', ', $allowed_types);
    exit;
}

// Generate reference ID (timestamp-based, no IP hardcoding)
$ref_id = 'PROC-' . strtoupper(substr(md5(microtime(true) . $vendor_id), 0, 10));

// Output
echo "AETHON DEFENSE SYSTEMS — PROCUREMENT PORTAL v2.4.1\n";
echo str_repeat("=", 52) . "\n";
echo "STATUS          : RECEIVED — PENDING REVIEW\n";
echo "REFERENCE ID    : {$ref_id}\n";
echo "REQUEST TYPE    : {$type}\n";
echo "VENDOR ID       : {$vendor_id}\n";
echo "PRIORITY        : {$priority}\n";
echo "ITEMS PARSED    : " . count($items_out) . "\n";
if (!empty($items_out)) {
    echo "LINE ITEMS:\n";
    foreach ($items_out as $it) echo $it . "\n";
}

// If any entity-expanded content ended up in fields (e.g., via XXE on a miscellaneous node)
// output it for vendor confirmation
$allText = $dom->textContent;
if (!empty($allText) && strlen($allText) > strlen($type . $vendor_id . $priority)) {
    echo str_repeat("-", 52) . "\n";
    echo "PARSED PAYLOAD CONTENT:\n";
    // Walk all text nodes and print any data nodes not already shown
    $xpath = new DOMXPath($dom);
    $nodes = $xpath->query('//*[not(self::type) and not(self::vendor_id) and not(self::priority) and not(self::sku) and not(self::quantity) and not(self::item) and not(self::items) and not(self::procurement)]');
    foreach ($nodes as $node) {
        $txt = trim($node->textContent);
        if (!empty($txt)) {
            echo "[" . htmlspecialchars($node->nodeName) . "]: " . $txt . "\n";
        }
    }
}

echo str_repeat("=", 52) . "\n";
echo "Your submission has been queued. A Supply Chain Analyst\n";
echo "will review within 2 business days.\n";
?>
