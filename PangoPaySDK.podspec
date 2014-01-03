Pod::Spec.new do |s|
    s.name              = 'PangoPaySDK'
    s.version           = '0.0.1'
    s.summary           = 'PangoPay connection and caching interface.'
    s.homepage          = 'https://github.com/PaynoPain/pangopay-objectivec-sdk'
    s.license           = {
        :type => 'GPL3',
        :file => 'LICENSE'
    }
    s.author            = {
        'Christian Bongardt' => 'chrbongardt@paynopain.com'
    }
    s.source            = {
        :git => 'https://github.com/PaynoPain/pangopay-objectivec-sdk.git',
	:tag => '0.2',
    }
    s.source_files      = 'Sources/'
    s.requires_arc      = true
    s.frameworks 	= 'Security'
end

