# Foundry, OpenAI and Cognitive Services
*Private DNS Zone integration for Private endpoints*

Two policies are available:

### Conditional policy
This policy supports kinds AIServices, OpenAI, and Cognitive Services. It has a fallback to the Cognitive services DNS zone if the service Kind is not AIServices or OpenAI.

[foundry-openai-cognitiveservices-conditional-dns-zone-integration.json](./foundry-openai-cognitiveservices-conditional-dns-zone-integration.json)

    - For Foundry (AIServices), it configures these zones:
        - privatelink.services.ai.azure.com
        - privatelink.cognitiveservices.azure.com
        - privatelink.openai.azure.com

    - For OpenAI, it configures these zones:
        - privatelink.openai.azure.com

    - For Cognitive Services, it configures these zones:
        - privatelink.cognitiveservices.azure.com

 <br>

### All in one policy
This policy configures all three available Private DNS Zones, regardless of which service Kind.

[foundry-dns-zone-integration-all-zones.json](./foundry-dns-zone-integration-all-zones.json)

    - For all service types, it configures:
        - privatelink.services.ai.azure.com
        - privatelink.cognitiveservices.azure.com
        - privatelink.openai.azure.com