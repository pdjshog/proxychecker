<?php

namespace App\Command;

use GuzzleHttp\Client;
use GuzzleHttp\Exception\GuzzleException;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class ProxyCheckerCommand extends Command
{
    protected static $defaultName = 'app:run';
    protected static $defaultDescription = 'checkproxies';

    /**
     * @throws GuzzleException
     */
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $guzzle = new Client();
        $output->writeln('getting list');

        $content = $guzzle->get('https://proxylist.geonode.com/api/proxy-list?limit=500&page=1&sort_by=lastChecked&sort_type=desc')
            ->getBody()->getContents();
        $proxies = json_decode($content, true);
        $output->writeln('processing list');

        foreach ($proxies['data'] as $proxy) {
            $proto = reset($proxy['protocols']);
            $string = "{$proto}://{$proxy['ip']}:{$proxy['port']}";
            try {
                $guzzle->request('GET', 'https://google.com', [
                    'timeout' => 1,
                    'proxy' => [
                        'https' => $string,
                        'http' => $string,
                    ],
                ]);
            } catch (\Throwable $exception) {
                $output->writeln("[DEAD] {$string}");
                continue;
            }

            $output->writeln("[LIVE] {$string}");
        }

        return Command::SUCCESS;
    }
}
