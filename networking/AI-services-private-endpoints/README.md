# Foundry, OpenAI and Cognitive Services
*Private DNS Zone integration for Private endpoints*

Two policies are available, a conditional one, which has a fallback to the Cognitive services DNS zone if the service Kind is not AIServices or OpenAI, and a policy that configures all three available Private DNS Zones.


- Conditional Policy: This policy conditionally updates Private endpoints with the releveant Private DNS Zone settings depending on the service Kind
[foundry-openai-cognitiveservices-conditional-dns-zone-integration.json](./foundry-openai-cognitiveservices-conditional-dns-zone-integration.json)

    - For Foundry, it configures these zones:
        - privatelink.services.ai.azure.com
        - privatelink.cognitiveservices.azure.com
        - privatelink.openai.azure.com

    - For OpenAI, it configures these zones:
        - privatelink.openai.azure.com

    - For Cognitive Services, it configures these zones:
        - privatelink.cognitiveservices.azure.com


- All in one policy: This policy configures all three available Private DNS Zones, regardless of which service Kind.
[foundry-dns-zone-integration-all-zones.json](./foundry-dns-zone-integration-all-zones.json)

    - For all service types, it configures:
        - privatelink.services.ai.azure.com
        - privatelink.cognitiveservices.azure.com
        - privatelink.openai.azure.com